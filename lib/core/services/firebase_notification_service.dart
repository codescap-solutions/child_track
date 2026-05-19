import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'package:child_track/core/services/background_task_service.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/app/auth/view_model/auth_repository.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/social_apps/view_model/bloc/app_lock_bloc.dart';
import 'package:child_track/app/social_apps/view_model/bloc/app_lock_event.dart';
import 'package:child_track/app/social_apps/view_model/app_lock_repository.dart';
import 'package:workmanager/workmanager.dart';
import 'package:child_track/core/services/csv_file_logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart' show GlobalKey, NavigatorState, MaterialPageRoute;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/app/chat/view/chat_screen.dart';
import 'package:child_track/app/chat/view_model/bloc/chat_bloc.dart';

/// Top-level function for handling background messages
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  
  // Initialize CSV Logger for background isolates
  await CsvFileLogger.instance.init();
  
  AppLogger.info('Background message received: ${message.messageId}');
  AppLogger.info('Background message data: ${message.data}');

  // Log to CSV for offline analysis
  CsvFileLogger.instance.write(
    tag: 'FCM',
    level: 'INFO',
    message:
        'BG message: type=${message.data['type']} id=${message.messageId} data=${message.data}',
  );

  if (message.data['type'] == 'SYNC_SCREEN_TIME') {
    AppLogger.info('Received SYNC_SCREEN_TIME command via FCM');
    try {
      // CRITICAL: Initialize WorkManager in background isolate.
      // When the app is killed, main() hasn't run, so WorkManager
      // is not initialized. Safe to call multiple times.
      await Workmanager().initialize(callbackDispatcher);
      await BackgroundTaskService.triggerImmediateSync();
      AppLogger.info('SYNC_SCREEN_TIME: WorkManager task scheduled');
    } catch (e) {
      AppLogger.error('SYNC_SCREEN_TIME: Failed to schedule sync: $e');
    }
  }

  if (message.data['type'] == 'SYNC_LOCKED_APPS' ||
      message.data['action'] == 'lock_apps' ||
      message.data['action'] == 'unlock_apps') {
    final action = message.data['action'] ?? message.data['type'] ?? 'unknown';
    AppLogger.info('Received $action command via FCM (background)');
    try {
      // Background isolate can't use MethodChannel to reach native plugins on some setups.
      // On Android, we fetch the lock list and write it to SharedPreferences,
      // which IS shared across isolates AND readable by native Kotlin code.
      // AppLockService reads 'flutter.locked_packages_csv' from FlutterSharedPreferences.
      await SharedPrefsService.init();

      // We need DioClient to call the API — initialize minimal deps
      if (!injector.isRegistered<SharedPrefsService>()) {
        await initializeDependencies();
      }

      final repo = injector<AppLockRepository>();
      final response = await repo.getChildLockedApps();

      if (response.isSuccess && response.data != null) {
        final packages = response.data!.lockedPackages
            .map((e) => e.packageName)
            .toList();

        // CRITICAL: Write using the EXACT key that AppLockService.kt reads.
        // AppLockService reads from FlutterSharedPreferences with key "flutter.locked_packages_csv".
        // Flutter's SharedPreferences plugin automatically prepends "flutter." to all keys,
        // so calling prefs.setString('locked_packages_csv', ...) writes "flutter.locked_packages_csv".
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('locked_packages_csv', packages.join(','));
        AppLogger.info(
          '$action (bg): Saved ${packages.length} packages to SharedPrefs CSV: $packages',
        );

        // Attempt to sync natively for iOS from background isolate
        if (Platform.isIOS) {
          try {
            const iosChannel = MethodChannel('com.truenyx.naviq/parental_control');
            await iosChannel.invokeMethod<bool>('updateLockList', packages);
            AppLogger.info('$action (bg): Synced to iOS native');
          } catch (iosErr) {
            AppLogger.error('$action (bg): iOS sync error: $iosErr');
          }
        }
      } else {
        AppLogger.error(
          '$action (bg): API failed: ${response.message}',
        );
      }
    } catch (e) {
      AppLogger.error('$action background sync error: $e');
    }
  }

  if (message.data['type'] == 'FORCE_REFRESH_DATA') {
    AppLogger.info('Received FORCE_REFRESH_DATA command via FCM (background)');
    try {
      await SharedPrefsService.init();
      final prefs = SharedPrefsService();
      final childId = prefs.getString('child_id');

      if (childId == null || childId.isEmpty) {
        AppLogger.warning('FORCE_REFRESH_DATA (bg): No child_id found');
        return;
      }

      // Initialize minimal dependencies for API calls
      if (!injector.isRegistered<SharedPrefsService>()) {
        await initializeDependencies();
      }

      await _performForceRefresh(childId);
      AppLogger.info('FORCE_REFRESH_DATA (bg): Sync completed successfully');
    } catch (e) {
      AppLogger.error('FORCE_REFRESH_DATA background error: $e');
    }
  }

  // Handle WEB_FILTER_UPDATE in background
  if (message.data['type'] == 'WEB_FILTER_UPDATE') {
    AppLogger.info('Received WEB_FILTER_UPDATE command via FCM (background)');
    try {
      final enabledStr = message.data['enabled']?.toString();
      final enabled = enabledStr == 'true';

      await SharedPrefsService.init();
      final prefs = SharedPrefsService();
      await prefs.setBool('block_18plus', enabled);

      AppLogger.info('WEB_FILTER_UPDATE (bg): Updated block_18plus to $enabled');
    } catch (e) {
      AppLogger.error('WEB_FILTER_UPDATE background error: $e');
    }
  }
}

/// Helper function to perform the actual data refresh and upload.
/// This is used by both foreground and background handlers.
Future<void> _performForceRefresh(String childId) async {
  try {
    AppLogger.info('🚀 Executing FORCE_REFRESH_DATA for $childId');

    // 1. Get Location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      AppLogger.error('Force Refresh: Failed to get location: $e');
    }

    // 2. Get Device Status
    int batteryLevel = 0;
    String batteryStatus = 'unknown';
    try {
      final battery = Battery();
      batteryLevel = await battery.batteryLevel;
      final state = await battery.batteryState;
      batteryStatus = state.toString().split('.').last;
    } catch (e) {
      AppLogger.error('Force Refresh: Failed to get battery: $e');
    }

    final childRepo = injector<ChildRepo>();

    // 3. Post Device Status
    final statusData = {
      "child_id": childId,
      "battery_level": batteryLevel,
      "battery_status": batteryStatus,
      "is_charging": batteryStatus == 'charging',
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };
    final statusResponse = await childRepo.postChildData(statusData);
    if (statusResponse.isSuccess) {
      AppLogger.info('✅ Force Refresh: Device status synced');
    } else {
      AppLogger.error(
        '❌ Force Refresh: Device status failed: ${statusResponse.message}',
      );
    }

    // 4. Post Location (if available)
    if (position != null) {
      final locationRepo = injector<ChildGoogleMapsRepo>();
      final locationInfo = await locationRepo.getAddressAndPlaceName(
        position.latitude,
        position.longitude,
      );

      final locationData = {
        "address": locationInfo?['address'] ?? 'Unknown Address',
        "place_name": locationInfo?['place_name'] ?? 'Unknown Place',
        "child_id": childId,
        "lat": position.latitude,
        "lng": position.longitude,
        "accuracy_m": position.accuracy,
        "speed_mps": position.speed,
        "bearing": position.heading,
        "timestamp": DateTime.now().toUtc().toIso8601String(),
      };
      final locationResponse = await childRepo.postChildLocation(locationData);
      if (locationResponse.isSuccess) {
        AppLogger.info('✅ Force Refresh: Location synced');
      } else {
        AppLogger.error(
          '❌ Force Refresh: Location failed: ${locationResponse.message}',
        );
      }
    } else {
      AppLogger.warning('⚠️ Force Refresh: Skipping location (not available)');
    }

    AppLogger.info('🚀 FORCE_REFRESH_DATA: Sync operation finished');
  } catch (e) {
    AppLogger.error('Error during _performForceRefresh: $e');
    rethrow;
  }
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() {
    return _instance;
  }

  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _notificationTapController =
      StreamController<RemoteMessage>.broadcast();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'naviq_notifications',
    'NaviQ Notifications',
    description: 'Notifications from NaviQ',
    importance: Importance.max,
  );

  Stream<RemoteMessage> get messageStream => _messageController.stream;
  Stream<RemoteMessage> get notificationTapStream =>
      _notificationTapController.stream;

  GlobalKey<NavigatorState>? _navigatorKey;
  void setNavigatorKey(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      AppLogger.info(
        'User granted permission: ${settings.authorizationStatus}',
      );

      // Initialize local notifications
      await _initLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Listen for token refresh and re-register with server
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        AppLogger.info('FCM Token refreshed: $newToken');
        // Re-register the new token with server
        registerTokenWithServer();
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification (terminated state)
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      AppLogger.info('Firebase Notification Service initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing Firebase Notification Service: $e');
    }
  }

  /// Initialize flutter_local_notifications
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        AppLogger.info('Local notification tapped: ${response.payload}');
        // Payload handling can trigger navigation if needed
      },
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      AppLogger.info('FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      AppLogger.error('Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('Foreground message received: ${message.messageId}');
    AppLogger.info('Message data: ${message.data}');
    AppLogger.info('Message notification: ${message.notification?.title}');

    // Log to CSV for offline analysis
    CsvFileLogger.instance.write(
      tag: 'FCM',
      level: 'INFO',
      message:
          'FG message: type=${message.data['type']} title=${message.notification?.title} data=${message.data}',
    );

    // Add to stream for listeners
    _messageController.add(message);

    // Handle SYNC_LOCKED_APPS in foreground — dispatch to AppLockBloc
    if (message.data['type'] == 'SYNC_LOCKED_APPS') {
      try {
        final appLockBloc = injector<AppLockBloc>();
        appLockBloc.add(SyncLockedAppsFromServer());
        AppLogger.info('SYNC_LOCKED_APPS: Dispatched to AppLockBloc');
      } catch (e) {
        AppLogger.error('SYNC_LOCKED_APPS foreground error: $e');
      }
      return; // Don't show notification
    }

    // Handle FORCE_REFRESH_DATA in foreground
    if (message.data['type'] == 'FORCE_REFRESH_DATA') {
      try {
        final prefs = injector<SharedPrefsService>();
        final childId = prefs.getString('child_id');
        if (childId != null && childId.isNotEmpty) {
          await _performForceRefresh(childId);
          AppLogger.info('FORCE_REFRESH_DATA (fg): Sync triggered');
        }
      } catch (e) {
        AppLogger.error('FORCE_REFRESH_DATA foreground error: $e');
      }
      return; // Don't show notification
    }

    // Handle WEB_FILTER_UPDATE in foreground
    if (message.data['type'] == 'WEB_FILTER_UPDATE') {
      try {
        final enabledStr = message.data['enabled']?.toString();
        final enabled = enabledStr == 'true';

        final prefs = injector<SharedPrefsService>();
        await prefs.setBool('block_18plus', enabled);
        AppLogger.info('WEB_FILTER_UPDATE (fg): Updated block_18plus to $enabled');
      } catch (e) {
        AppLogger.error('WEB_FILTER_UPDATE foreground error: $e');
      }
      return; // Don't show notification
    }

    // Show local notification for foreground messages
    _showLocalNotification(message);
  }

  /// Show a local notification based on FCM message data
  void _showLocalNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final notification = message.notification;

    String title = notification?.title ?? 'NaviQ';
    String body = notification?.body ?? '';

    // Build title/body from data payload if notification payload is empty
    if (notification == null && type != null) {
      final childName = data['child_name'] ?? 'Child';
      switch (type) {
        case 'SOS':
          title = '🚨 SOS from $childName!';
          body = 'Emergency alert received. Tap to view location.';
          break;
        case 'SAFE_PLACE_ARRIVAL':
          title = '$childName arrived safely';
          body = 'Arrived at ${data['place_name'] ?? 'safe place'}';
          break;
        case 'SAFE_PLACE_DEPARTURE':
          title = '$childName left ${data['place_name'] ?? 'safe place'}';
          body = 'Departed from ${data['place_name'] ?? 'safe place'}';
          break;
        case 'TRIP_STARTED':
          title = '$childName is on the move';
          body = 'Started from ${data['start_place'] ?? 'unknown'}';
          break;
        case 'TRIP_ENDED':
          title = '$childName\'s trip ended';
          body = data['from_place'] != null && data['to_place'] != null
              ? '${data['from_place']} → ${data['to_place']} (${data['distance_km'] ?? '?'} km)'
              : 'Trip completed';
          break;
        case 'LOW_BATTERY':
          title = '$childName\'s device battery low';
          body = 'Battery at ${data['battery_percentage'] ?? '?'}%';
          break;
        case 'DEVICE_OFFLINE':
          title = '$childName\'s device is offline';
          body = 'Device went offline. Last seen recently.';
          break;
        case 'CHAT_MESSAGE':
          title = data['sender_name'] ?? 'New Message';
          body = data['text'] ?? 'Tap to view';
          break;
        case 'SYNC_SCREEN_TIME':
        case 'SYNC_LOCKED_APPS':
          // Silent — don't show a notification
          return;
        default:
          title = 'NaviQ';
          body = 'You have a new notification';
      }
    }

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: type == 'SOS' ? Importance.max : Importance.high,
          priority: type == 'SOS' ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: type,
    );
  }

  /// Handle notification tap (when app is in background or terminated)
  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info('Notification tapped: ${message.messageId}');
    AppLogger.info('Notification data: ${message.data}');

    // Log to CSV
    CsvFileLogger.instance.write(
      tag: 'FCM',
      level: 'INFO',
      message:
          'Notification tapped: type=${message.data['type']} data=${message.data}',
    );

    // Add to stream for navigation or other actions
    _notificationTapController.add(message);

    // Automatic navigation for CHAT_MESSAGE
    if (message.data['type'] == 'CHAT_MESSAGE' && _navigatorKey?.currentState != null) {
      final chatId = message.data['chat_id'];
      final senderId = message.data['sender_id'];
      final senderName = message.data['sender_name'] ?? 'Support';

      if (senderId != null) {
        _navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: injector<ChatBloc>(),
              child: ChatScreen(
                chatId: chatId,
                recipientId: senderId,
                recipientName: senderName,
              ),
            ),
          ),
        );
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      AppLogger.info('FCM token deleted');
    } catch (e) {
      AppLogger.error('Error deleting FCM token: $e');
    }
  }

  /// Register FCM token with the backend server.
  /// Determines whether user is parent or child from SharedPrefs.
  Future<void> registerTokenWithServer() async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      AppLogger.warning('FCM token is null, cannot register with server');
      return;
    }

    try {
      final prefs = injector<SharedPrefsService>();
      final parentId = prefs.getString('parent_id');
      final childId = prefs.getString('child_id');

      // Parent flow: has parent_id and NO child_id (or child_id is from parent's selected child)
      if (parentId != null && parentId.isNotEmpty) {
        // Check if this is a parent user (not a child device)
        // A child device will have child_id but NO parent_id
        final authRepo = injector<AuthRepository>();
        final response = await authRepo.registerParentFcmToken(_fcmToken!);
        if (response.isSuccess) {
          AppLogger.info('Parent FCM token registered with server');
        } else {
          AppLogger.error(
            'Failed to register parent FCM token: ${response.message}',
          );
        }
      } else if (childId != null && childId.isNotEmpty) {
        // Child flow
        final childRepo = injector<ChildRepo>();
        final response = await childRepo.registerChildFcmToken(
          childId: childId,
          fcmToken: _fcmToken!,
        );
        if (response.isSuccess) {
          AppLogger.info('Child FCM token registered with server');
        } else {
          AppLogger.error(
            'Failed to register child FCM token: ${response.message}',
          );
        }
      } else {
        AppLogger.warning(
          'No parent_id or child_id found, skipping FCM token registration',
        );
      }
    } catch (e) {
      AppLogger.error('Error registering FCM token with server: $e');
    }
  }

  /// Remove FCM token from server (call before logout)
  Future<void> removeTokenFromServer() async {
    try {
      final prefs = injector<SharedPrefsService>();
      final parentId = prefs.getString('parent_id');
      final childId = prefs.getString('child_id');

      if (parentId != null && parentId.isNotEmpty) {
        final authRepo = injector<AuthRepository>();
        final response = await authRepo.removeParentFcmToken();
        if (response.isSuccess) {
          AppLogger.info('Parent FCM token removed from server');
        } else {
          AppLogger.error(
            'Failed to remove parent FCM token: ${response.message}',
          );
        }
      } else if (childId != null && childId.isNotEmpty) {
        final childRepo = injector<ChildRepo>();
        final response = await childRepo.removeChildFcmToken(childId: childId);
        if (response.isSuccess) {
          AppLogger.info('Child FCM token removed from server');
        } else {
          AppLogger.error(
            'Failed to remove child FCM token: ${response.message}',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error removing FCM token from server: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _messageController.close();
    _notificationTapController.close();
  }
}

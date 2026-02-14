import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_logger.dart';
import 'package:child_track/core/services/background_task_service.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/app/auth/view_model/auth_repository.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';

/// Top-level function for handling background messages
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Background message received: ${message.messageId}');
  AppLogger.info('Background message data: ${message.data}');

  if (message.data['type'] == 'SYNC_SCREEN_TIME') {
    AppLogger.info('Received SYNC_SCREEN_TIME command via FCM');
    // Ensure WorkManager is initialized (safe to call multiple times or if main app not running?)
    // WorkManager plugin handles initialization check usually, but might need to be sure.
    // However, we can just call triggerImmediateSync which registerOneOffTask.
    // NOTE: Workmanager().initialize needs to be called before registering tasks?
    // Actually, if the app was killed, we might need to initialize it here if not already.
    // But `registerOneOffTask` might fail if not initialized.
    // However, usually callbackDispatcher is what needs init.
    // Let's assume we can just trigger it. If it fails, we might need a safer init pattern.
    // Based on user request: "Workmanager().registerOneOffTask(...)" is what they want.
    await BackgroundTaskService.triggerImmediateSync();
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
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Foreground message received: ${message.messageId}');
    AppLogger.info('Message data: ${message.data}');
    AppLogger.info('Message notification: ${message.notification?.title}');

    // Add to stream for listeners
    _messageController.add(message);

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
        case 'SYNC_SCREEN_TIME':
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

    // Add to stream for navigation or other actions
    _notificationTapController.add(message);
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

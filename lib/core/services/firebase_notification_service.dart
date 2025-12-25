import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/app_logger.dart';

/// Top-level function for handling background messages
/// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Background message received: ${message.messageId}');
  AppLogger.info('Background message data: ${message.data}');
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

  Stream<RemoteMessage> get messageStream => _messageController.stream;
  Stream<RemoteMessage> get notificationTapStream =>
      _notificationTapController.stream;

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info('User granted permission: ${settings.authorizationStatus}');

      // Get FCM token
      await _getFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        AppLogger.info('FCM Token refreshed: $newToken');
        _messageController.add(RemoteMessage(
          messageId: 'token_refresh',
          data: {'token': newToken},
        ));
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification (terminated state)
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      AppLogger.info('Firebase Notification Service initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing Firebase Notification Service: $e');
    }
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

    // You can show a local notification here if needed
    // For now, we'll just log it and add to stream
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

  /// Dispose resources
  void dispose() {
    _messageController.close();
    _notificationTapController.close();
  }
}


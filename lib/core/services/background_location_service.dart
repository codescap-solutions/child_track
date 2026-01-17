import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/services/connectivity/bloc/connectivity_bloc.dart';
import 'package:child_track/core/utils/structured_logger.dart';
import 'package:child_track/core/services/location_state_machine.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  /// Initialize the background service
  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'child_track_location', // id
      'Location Tracking', // title
      description: 'Tracking your location in background', // description
      importance: Importance.low, // importance must be at low or higher level
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Manual start for control
        isForegroundMode: true,
        notificationChannelId: 'child_track_location',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking Active',
        foregroundServiceNotificationId: 888,
        // Crucial for foreground service type
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start the background service
  Future<void> start() async {
    final service = FlutterBackgroundService();
    StructuredLogger.log(LogTag.BG, 'Starting service manually');
    await service.startService();
  }

  /// Stop the background service
  Future<void> stop() async {
    final service = FlutterBackgroundService();
    StructuredLogger.log(LogTag.BG, 'Stopping service manually');
    service.invoke('stop');
  }

  /// Check if service is running
  Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

// Global reference for stream subscription to handle cancellation
StreamSubscription<Position>? _positionSubscription;
LocationStateMachine? _stateMachine;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    StructuredLogger.log(LogTag.BG, 'Service onStart initiated');

    // 1. Service Controls
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      StructuredLogger.log(LogTag.BG, 'Stop signal received');
      _positionSubscription?.cancel();
      service.stopSelf();
    });

    // 2. Initialize Dependencies
    await SharedPrefsService.init();
    final sharedPrefsService = SharedPrefsService();
    final connectivity = Connectivity();
    final connectivityBloc = ConnectivityBloc(connectivity: connectivity);
    final dioClient = DioClient(connectivityBloc: connectivityBloc);

    final childRepo = ChildRepo(
      dioClient: dioClient,
      sharedPrefsService: sharedPrefsService,
    );
    final childLocationRepo = ChildGoogleMapsRepo();

    // 3. Initialize State Machine
    _stateMachine = LocationStateMachine(
      childRepo: childRepo,
      locationRepo: childLocationRepo,
      prefs: sharedPrefsService,
    );

    // 4. Configure Location Settings
    // Use platform-specific settings for best performance/uptime
    LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10m filter to save battery
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 5), // Min interval
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "NaviQ Active",
          notificationText: "Tracking location...",
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
          ), // Ensure this icon exists
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness, // Helps keep alive during movement
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false, // CRITICAL for background
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    // 5. Start Stream
    StructuredLogger.log(LogTag.BG, 'Subscribing to location stream');
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            // Pass to State Machine
            _stateMachine?.processLocation(position);

            // Update Android Notification timestamp to show aliveness
            if (service is AndroidServiceInstance) {
              // Update notification content casually if needed,
              // but AndroidSettings above manages the foreground notification mostly.
              // Explicit updates can be done like:
              service.setForegroundNotificationInfo(
                title: "NaviQ Active",
                content: "Moving at ${position.speed.toStringAsFixed(1)} m/s",
              );
            }
          },
          onError: (e) {
            StructuredLogger.log(LogTag.BG, 'Stream Error', error: e);
          },
        );
  } catch (e) {
    StructuredLogger.log(LogTag.BG, 'onStart Fatal Error', error: e);
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  StructuredLogger.log(LogTag.BG, 'iOS Background Fetch Triggered');
  return true;
}

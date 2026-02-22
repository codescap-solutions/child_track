import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/services/connectivity/bloc/connectivity_bloc.dart';
import 'package:child_track/core/utils/structured_logger.dart';
import 'package:child_track/core/services/location_batch_uploader.dart';
import 'package:child_track/core/services/location_queue.dart';
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
      'child_track_location',
      'Location Tracking',
      description: 'Tracking your location in background',
      importance: Importance.high,
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
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'child_track_location',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking Active',
        foregroundServiceNotificationId: 888,
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
    try {
      final service = FlutterBackgroundService();
      final running = await service.isRunning();
      if (running) {
        StructuredLogger.log(
          LogTag.BG,
          'Service already running, skipping start',
        );
        return;
      }
      StructuredLogger.log(LogTag.BG, 'Starting service manually');
      await service.startService();
    } catch (e) {
      StructuredLogger.log(LogTag.BG, 'Failed to start service', error: e);
    }
  }

  /// Stop the background service
  Future<void> stop() async {
    try {
      final service = FlutterBackgroundService();
      StructuredLogger.log(LogTag.BG, 'Stopping service manually');
      service.invoke('stop');
    } catch (e) {
      StructuredLogger.log(LogTag.BG, 'Failed to stop service', error: e);
    }
  }

  /// Check if service is running
  Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

// ====================================================================
// FOREGROUND SERVICE ISOLATE
// ====================================================================

StreamSubscription<Position>? _positionSubscription;
LocationBatchUploader? _batchUploader;

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    StructuredLogger.log(LogTag.BG, 'Service onStart initiated');

    // CRITICAL: Set foreground IMMEDIATELY to satisfy Android's ~10s timeout
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
    }

    // ── Service Controls ──────────────────────────────────────────────
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });
      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) async {
      StructuredLogger.log(LogTag.BG, 'Stop signal received');
      await _shutdownGracefully(service);
    });

    service.on('stop').listen((event) async {
      StructuredLogger.log(LogTag.BG, 'Stop (legacy) signal received');
      await _shutdownGracefully(service);
    });

    // ── Initialize Dependencies ───────────────────────────────────────
    await SharedPrefsService.init();
    final sharedPrefsService = SharedPrefsService();
    final connectivity = Connectivity();
    final connectivityBloc = ConnectivityBloc(connectivity: connectivity);
    final dioClient = DioClient(
      connectivityBloc: connectivityBloc,
      sharedPrefsService: sharedPrefsService,
    );

    final childRepo = ChildRepo(
      dioClient: dioClient,
      sharedPrefsService: sharedPrefsService,
    );

    // ── Initialize Persistent Queue + Batch Uploader ──────────────────
    final queue = LocationQueue(prefs: sharedPrefsService);

    _batchUploader = LocationBatchUploader(
      childRepo: childRepo,
      prefs: sharedPrefsService,
      queue: queue,
    );

    // start() loads any persisted points from a previous kill/crash
    await _batchUploader!.start();

    // ── Configure Location Settings ───────────────────────────────────
    LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 15),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "NaviQ Active",
          notificationText: "Tracking location...",
          notificationIcon: AndroidResource(name: 'ic_launcher'),
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    // ── Start GPS Stream ──────────────────────────────────────────────
    StructuredLogger.log(LogTag.BG, 'Subscribing to location stream');
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _batchUploader?.addPoint(position);

            if (service is AndroidServiceInstance) {
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

/// Graceful shutdown — flush + persist + stop
Future<void> _shutdownGracefully(ServiceInstance service) async {
  _positionSubscription?.cancel();
  _positionSubscription = null;
  await _batchUploader?.dispose();
  _batchUploader = null;
  service.stopSelf();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  StructuredLogger.log(LogTag.BG, 'iOS Background Fetch Triggered');
  return true;
}

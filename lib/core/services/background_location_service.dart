import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:battery_plus/battery_plus.dart';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/core/services/csv_file_logger.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/services/connectivity/bloc/connectivity_bloc.dart';
import 'package:child_track/core/utils/structured_logger.dart';
import 'package:child_track/core/services/location_state_machine.dart';
import 'package:child_track/core/services/tracking/tracking_profile_manager.dart';
import 'package:child_track/core/services/tracking/tracking_config_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      importance: Importance.low,
      showBadge: false,
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

  Future<void> start() async {
    try {
      final service = FlutterBackgroundService();
      final running = await service.isRunning();
      if (running) {
        StructuredLogger.log(LogTag.BG, 'Service already running, skipping start');
        return;
      }
      StructuredLogger.log(LogTag.BG, 'Starting service manually');
      await service.startService();
    } catch (e) {
      StructuredLogger.log(LogTag.BG, 'Failed to start service', error: e);
    }
  }

  Future<void> stop() async {
    try {
      final service = FlutterBackgroundService();
      StructuredLogger.log(LogTag.BG, 'Stopping service manually');
      service.invoke('stop');
    } catch (e) {
      StructuredLogger.log(LogTag.BG, 'Failed to stop service', error: e);
    }
  }

  Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

// ── Global stream state ──────────────────────────────────────────────────────

StreamSubscription<Position>? _positionSubscription;
StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
LocationStateMachine? _stateMachine;

/// Adaptive tracking profile manager (shared between stream restarts).
final _profileManager = TrackingProfileManager();

/// Restart the location stream whenever the profile changes.
void _startLocationStream(ServiceInstance service) {
  _positionSubscription?.cancel();

  final LocationSettings settings;
  if (Platform.isAndroid) {
    settings = _profileManager.buildAndroidSettings();
  } else if (Platform.isIOS) {
    settings = _profileManager.buildAppleSettings();
  } else {
    settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _profileManager.currentConfig.distanceFilter,
    );
  }

  StructuredLogger.log(
    LogTag.BG,
    'Starting stream • profile=${_profileManager.currentProfile.name} '
    '• interval=${_profileManager.currentConfig.interval.inSeconds}s '
    '• filter=${_profileManager.currentConfig.distanceFilter}m',
  );

  _positionSubscription =
      Geolocator.getPositionStream(locationSettings: settings).listen(
    (Position position) {
      _stateMachine?.processLocation(position);

      // Dynamically adapt tracking profile based on speed
      final changed =
          _profileManager.updateFromSpeed(position.speed < 0 ? 0 : position.speed);
      if (changed) {
        StructuredLogger.log(
          LogTag.BG,
          'Profile changed → ${_profileManager.currentProfile.name}. Restarting stream.',
        );
        // Restart stream with new settings
        _startLocationStream(service);
      }

      // Update notification
      if (service is AndroidServiceInstance) {
        final sm = _stateMachine;
        String content;
        if (sm != null && sm.isTripTracking) {
          final mode = sm.tripMode == BgTripMode.walking ? 'Walking' : 'Vehicle';
          content =
              'Trip ($mode) • ${(position.speed * 3.6).toStringAsFixed(1)} km/h';
        } else {
          content =
              'Tracking • ${_profileManager.currentConfig.label} mode';
        }
        service.setForegroundNotificationInfo(
          title: 'NaviQ Active',
          content: content,
        );
      }
    },
    onError: (e) {
      StructuredLogger.log(LogTag.BG, 'Stream Error', error: e);
    },
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    await dotenv.load(fileName: '.env');

    await CsvFileLogger.instance.init();
    StructuredLogger.log(LogTag.BG, 'Service onStart initiated');

    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
    }

    // Service control listeners
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((_) => service.setAsForegroundService());
      service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
    }

    service.on('stopService').listen((_) {
      StructuredLogger.log(LogTag.BG, 'Stop signal received');
      _positionSubscription?.cancel();
      _serviceStatusSubscription?.cancel();
      _stateMachine?.dispose();
      service.stopSelf();
    });

    // Allow profile override from UI isolate
    service.on('setProfile').listen((event) {
      final profileName = event?['profile'] as String?;
      if (profileName != null) {
        final p = TrackingProfile.values.firstWhere(
          (e) => e.name == profileName,
          orElse: () => TrackingProfile.still,
        );
        final changed = _profileManager.setProfile(p);
        if (changed) _startLocationStream(service);
      }
    });

    // Dependencies
    await SharedPrefsService.init();
    final sharedPrefsService = SharedPrefsService();

    if (sharedPrefsService.isParent) {
      StructuredLogger.log(
        LogTag.BG,
        'Parent device detected – killing service',
      );
      service.stopSelf();
      return;
    }

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
    final childLocationRepo = ChildGoogleMapsRepo();
    final battery = Battery();

    final trackingConfigService = TrackingConfigService(
      dio: dioClient,
      prefs: sharedPrefsService,
    );

    _stateMachine = LocationStateMachine(
      childRepo: childRepo,
      locationRepo: childLocationRepo,
      prefs: sharedPrefsService,
      battery: battery,
      configService: trackingConfigService,
    );

    // Start with 'still' profile — adapts on first position
    _startLocationStream(service);

    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        StructuredLogger.log(
          LogTag.BG,
          'Location Service Status: $status',
        );
        if (status == ServiceStatus.enabled) {
          _startLocationStream(service);
        } else {
          _positionSubscription?.cancel();
        }
      },
      onError: (e) {
        StructuredLogger.log(LogTag.BG, 'Service Status Stream Error', error: e);
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

  // Previously a no-op. iOS invokes this — instead of keeping the continuous
  // position stream from onStart/onForeground alive — once the app has been
  // backgrounded long enough for iOS to suspend it. iOS schedules background
  // fetch opportunistically (commonly tens of minutes apart, entirely OS
  // controlled), so doing nothing here meant location pings — and therefore
  // geofence detection, which depends on them (see LocationStateMachine) —
  // could stall for that entire window until the app was foregrounded again.
  // Take a single quick fix and post it so the server's existing near-real-time
  // geofence pipeline (QueueService → geofence.service.checkGeofencesBatch)
  // has something fresh to evaluate instead of waiting for app resume.
  try {
    await dotenv.load(fileName: '.env');
    await SharedPrefsService.init();
    final prefs = SharedPrefsService();

    if (prefs.isParent) return true;

    final childId = prefs.getString('child_id');
    if (childId == null || childId.isEmpty) {
      StructuredLogger.log(LogTag.BG, 'iOS Background Fetch: no child_id – skipping');
      return true;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );

    final dioClient = DioClient(sharedPrefsService: prefs);
    final childRepo = ChildRepo(dioClient: dioClient, sharedPrefsService: prefs);

    final response = await childRepo.postChildLocation({
      'child_id': childId,
      'lat': position.latitude,
      'lng': position.longitude,
      'accuracy': position.accuracy,
      'accuracy_m': position.accuracy,
      'speed': position.speed < 0 ? 0.0 : position.speed,
      'speed_mps': position.speed < 0 ? 0.0 : position.speed,
      'bearing': position.heading < 0 ? 0.0 : position.heading,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    StructuredLogger.log(
      LogTag.BG,
      'iOS Background Fetch: posted location fix (success=${response.isSuccess})',
    );
  } catch (e) {
    StructuredLogger.log(LogTag.BG, 'iOS Background Fetch: failed to post location', error: e);
  }

  return true;
}

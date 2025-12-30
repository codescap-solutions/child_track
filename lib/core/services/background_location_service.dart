import 'dart:async';
import 'dart:ui';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/services/connectivity/bloc/connectivity_bloc.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  /// Initialize the background service
  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'child_track_location',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking your location in background',
        foregroundServiceNotificationId: 888,
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
    final isRunning = await service.isRunning();
    
    if (!isRunning) {
      AppLogger.info('Starting background location service');
      await service.startService();
    } else {
      AppLogger.info('Background location service already running');
    }
  }

  /// Stop the background service
  Future<void> stop() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    
    if (isRunning) {
      AppLogger.info('Stopping background location service');
      service.invoke('stop');
    }
  }

  /// Check if service is running
  Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize SharedPreferences in background isolate
  await SharedPrefsService.init();
  
  // Initialize dependencies in background isolate
  final sharedPrefsService = SharedPrefsService();
  final connectivity = Connectivity();
  final connectivityBloc = ConnectivityBloc(connectivity: connectivity);
  final dioClient = DioClient(connectivityBloc: connectivityBloc);
  final childRepo = ChildRepo(
    dioClient: dioClient,
    sharedPrefsService: sharedPrefsService,
  );
  final childLocationRepo = ChildGoogleMapsRepo();

  bool isTripTracking = false;
  List<Position> tripLocations = [];
  DateTime? tripStartTime;
  Position? lastTrackedLocation;
  DateTime? lastMovementTime;
  Timer? locationTimer;
  Timer? tripLocationTimer;
  Timer? tripEndCheckTimer;

  // Function to post trip event (declared early for use in other functions)
  Future<void> postTripEvent() async {
    try {
      final childId = sharedPrefsService.getString('child_id');
      final parentId = sharedPrefsService.getString('parent_id');
      
      // Only post if logged in as child (has child_id) and NOT as parent
      if (childId == null || childId.isEmpty || (parentId != null && parentId.isNotEmpty)) {
        AppLogger.warning('Not logged in as child, skipping trip event post');
        return;
      }

      if (tripLocations.length < 2 || tripStartTime == null) {
        return;
      }

      final startLocation = tripLocations.first;
      final endLocation = tripLocations.last;
      final endTime = DateTime.now();
      final duration = endTime.difference(tripStartTime!);

      // Get dynamic address and place name for start and end locations
      final startLocationInfo = await childLocationRepo.getAddressAndPlaceName(
        startLocation.latitude,
        startLocation.longitude,
      );
      final endLocationInfo = await childLocationRepo.getAddressAndPlaceName(
        endLocation.latitude,
        endLocation.longitude,
      );

      // Calculate distance and max speed
      double totalDistance = 0.0;
      double maxSpeed = 0.0;

      for (int i = 0; i < tripLocations.length - 1; i++) {
        final distance = await childLocationRepo.getDistanceBetweenTwoPoints(
          tripLocations[i],
          tripLocations[i + 1],
        );
        totalDistance += distance;

        final speed = tripLocations[i].speed * 3.6; // Convert m/s to km/h
        if (speed > maxSpeed) {
          maxSpeed = speed;
        }
      }

      final requestBody = {
        "child_id": childId,
        "event_type": "ride",
        "distance_m": totalDistance.round(),
        "duration_s": duration.inSeconds,
        "max_speed_kmph": maxSpeed,
        "start_lat": startLocation.latitude,
        "start_lng": startLocation.longitude,
        "start_address": startLocationInfo?['address'] ?? 'Unknown',
        "start_place_name": startLocationInfo?['place_name'] ?? 'Unknown',
        "end_lat": endLocation.latitude,
        "end_lng": endLocation.longitude,
        "end_address": endLocationInfo?['address'] ?? 'Unknown',
        "end_place_name": endLocationInfo?['place_name'] ?? 'Unknown',
        "start_time": tripStartTime!.toIso8601String(),
        "end_time": endTime.toIso8601String(),
      };

      await childRepo.postTripEvent(requestBody);
      AppLogger.info('Trip event posted from background service');
    } catch (e) {
      AppLogger.error('Error posting trip event from background: $e');
    }
  }

  // Function to update trip location (declared early for use in timer)
  Future<void> updateTripLocation() async {
    if (!isTripTracking) {
      tripLocationTimer?.cancel();
      return;
    }

    try {
      final childId = sharedPrefsService.getString('child_id');
      final parentId = sharedPrefsService.getString('parent_id');
      
      // Only track if logged in as child (has child_id) and NOT as parent
      if (childId == null || childId.isEmpty || (parentId != null && parentId.isNotEmpty)) {
        AppLogger.warning('Not logged in as child, stopping trip tracking');
        isTripTracking = false;
        tripLocationTimer?.cancel();
        service.stopSelf();
        return;
      }

      final newLocation = await childLocationRepo.getChildLocation();
      if (newLocation == null) return;

      // Check if child moved 10m or more from last tracked location
      bool shouldTrack = true;
      if (lastTrackedLocation != null) {
        final distance = await childLocationRepo.getDistanceBetweenTwoPoints(
          lastTrackedLocation!,
          newLocation,
        );
        shouldTrack = distance >= 10.0;
      }

      if (shouldTrack) {
        tripLocations.add(newLocation);
        lastTrackedLocation = newLocation;
        lastMovementTime = DateTime.now(); // Update last movement time

        // Get dynamic address and place name from coordinates
        final locationInfo = await childLocationRepo.getAddressAndPlaceName(
          newLocation.latitude,
          newLocation.longitude,
        );

        // Post location update to API
        final requestBody = {
          "address": locationInfo?['address'] ?? 'Unknown',
          "place_name": locationInfo?['place_name'] ?? 'Unknown',
          "child_id": childId,
          "lat": newLocation.latitude,
          "lng": newLocation.longitude,
          "accuracy_m": newLocation.accuracy,
          "speed_mps": newLocation.speed,
          "bearing": newLocation.heading,
          "timestamp": DateTime.now().toIso8601String(),
        };
        await childRepo.postChildLocation(requestBody);
        AppLogger.info('Trip location updated from background service');
      }
    } catch (e) {
      AppLogger.error('Error updating trip location from background: $e');
    }
  }

  // Function to start trip location timer
  void startTripLocationTimer() {
    tripLocationTimer?.cancel();
    tripLocationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!isTripTracking) {
        tripLocationTimer?.cancel();
        return;
      }
      updateTripLocation();
    });
  }

  // Function to check if trip should end (no movement for 2 minutes)
  Future<void> checkTripEnd() async {
    if (!isTripTracking || lastMovementTime == null) return;

    final timeSinceLastMovement = DateTime.now().difference(lastMovementTime!);
    if (timeSinceLastMovement.inMinutes >= 2) {
      // Trip ended - post trip event
      await postTripEvent();
      
      // Reset trip tracking
      isTripTracking = false;
      tripLocations.clear();
      tripStartTime = null;
      tripLocationTimer?.cancel();
      tripEndCheckTimer?.cancel();
      AppLogger.info('Trip ended automatically (no movement for 2 minutes)');
    }
  }

  // Listen for service invocations
  service.on('stop').listen((event) {
    locationTimer?.cancel();
    tripLocationTimer?.cancel();
    tripEndCheckTimer?.cancel();
    service.stopSelf();
  });

  // Function to get and post location
  Future<void> postLocation() async {
    try {
      final childId = sharedPrefsService.getString('child_id');
      final parentId = sharedPrefsService.getString('parent_id');
      
      // Only track if logged in as child (has child_id) and NOT as parent
      if (childId == null || childId.isEmpty || (parentId != null && parentId.isNotEmpty)) {
        AppLogger.warning('Not logged in as child, stopping location tracking');
        service.stopSelf();
        return;
      }

      final location = await childLocationRepo.getChildLocation();
      if (location == null) {
        AppLogger.warning('Failed to get location');
        return;
      }

      // Check if child moved 10m or more (and not already tracking a trip)
      if (lastTrackedLocation != null && !isTripTracking) {
        final distance = await childLocationRepo.getDistanceBetweenTwoPoints(
          lastTrackedLocation!,
          location,
        );

        // If moved 10m or more, automatically start trip tracking
        if (distance >= 10.0) {
          isTripTracking = true;
          tripStartTime = DateTime.now();
          lastMovementTime = DateTime.now();
          tripLocations = [lastTrackedLocation!, location];
          lastTrackedLocation = location;
          AppLogger.info('Trip tracking started automatically');
          startTripLocationTimer();
          
          // Start trip end check timer
          tripEndCheckTimer?.cancel();
          tripEndCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
            checkTripEnd();
          });
          return;
        }
      }

      // Get dynamic address and place name from coordinates
      final locationInfo = await childLocationRepo.getAddressAndPlaceName(
        location.latitude,
        location.longitude,
      );

      final requestBody = {
        "address": locationInfo?['address'] ?? 'Unknown',
        "place_name": locationInfo?['place_name'] ?? 'Unknown',
        "child_id": childId,
        "lat": location.latitude,
        "lng": location.longitude,
        "accuracy_m": location.accuracy,
        "speed_mps": location.speed,
        "bearing": location.heading,
        "timestamp": DateTime.now().toIso8601String(),
      };

      await childRepo.postChildLocation(requestBody);
      lastTrackedLocation = location;
      AppLogger.info('Location posted from background service');
    } catch (e) {
      AppLogger.error('Error posting location from background: $e');
    }
  }


  // Start location tracking timer (every 30 seconds)
  locationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    postLocation();
  });

  // Initial location post
  postLocation();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}


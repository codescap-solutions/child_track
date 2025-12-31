import 'dart:async';
import 'package:child_track/app/childapp/model/scree_time_model.dart';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
part 'child_event.dart';
part 'child_state.dart';

class ChildBloc extends Bloc<ChildEvent, ChildState> {
  final ChildInfoService _deviceInfoService;
  final ChildRepo _childRepo;
  final ChildGoogleMapsRepo _childLocationRepo;
  final SharedPrefsService _sharedPrefsService;
  // Timers
  Timer? _deviceInfoTimer; // 10 minutes
  Timer? _screenTimeTimer; // 1 hour
  Timer? _childLocationTimer; // 30 seconds
  Timer? _tripLocationTimer; // 5 seconds for trip tracking

  ChildBloc({
    required SharedPrefsService sharedPrefsService,
    required ChildInfoService deviceInfoService,
    required ChildRepo childRepo,
    required ChildGoogleMapsRepo childLocationRepo,
  }) : _deviceInfoService = deviceInfoService,
       _childRepo = childRepo,
       _childLocationRepo = childLocationRepo,
       _sharedPrefsService = sharedPrefsService,
       super(ChildDeviceInfoLoaded.initial()) {
    on<LoadDeviceInfo>(_onLoadDeviceInfo);
    on<PostDeviceInfo>(_onPostDeviceInfo);
    on<GetScreenTime>(_onGetScreenTime);
    on<PostScreenTime>(_onPostScreenTime);
    on<GetChildLocation>(_onGetChildLocation);
    on<PostChildLocation>(_onPostChildLocation);
    on<StartTripTracking>(_onStartTripTracking);
    on<StopTripTracking>(_onStopTripTracking);
    on<UpdateTripLocation>(_onUpdateTripLocation);
  }
  void onInitialize() {
    final childId = _sharedPrefsService.getString('child_id');
    final parentId = _sharedPrefsService.getString('parent_id');

    // Only initialize if user is logged in as child (has child_id) and NOT as parent
    if (childId != null &&
        childId.isNotEmpty &&
        (parentId == null || parentId.isEmpty)) {
      AppLogger.info('ChildBloc: Initializing for child_id: $childId');
      add(LoadDeviceInfo());
      add(GetScreenTime());
      add(GetChildLocation());
    } else {
      AppLogger.info(
        'ChildBloc: Skipping initialization - not logged in as child',
      );
      // Stop any running timers
      _stopAllTimers();
    }
  }

  /// Stop all timers and cleanup
  void _stopAllTimers() {
    _stopDeviceInfoTimer();
    _stopScreenTimeTimer();
    _stopChildLocationTimer();
    _stopTripLocationTimer();
  }

  /// Public method to stop all child tracking activities
  void stopChildTracking() {
    AppLogger.info('ChildBloc: Stopping all child tracking activities');
    _stopAllTimers();
  }

  /// Check if user is logged in as child
  bool _isChildLoggedIn() {
    final childId = _sharedPrefsService.getString('child_id');
    final parentId = _sharedPrefsService.getString('parent_id');
    return childId != null &&
        childId.isNotEmpty &&
        (parentId == null || parentId.isEmpty);
  }

  Future<void> _onLoadDeviceInfo(
    LoadDeviceInfo event,
    Emitter<ChildState> emit,
  ) async {
    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      emit(ChildDeviceInfoLoaded(deviceInfo: deviceInfo));
      add(PostDeviceInfo(deviceInfo: deviceInfo));
    } catch (e) {
      AppLogger.error('Failed to load device info: ${e.toString()}');
    }
  }

  Future<void> _onPostDeviceInfo(
    PostDeviceInfo event,
    Emitter<ChildState> emit,
  ) async {
    // Check if user is still logged in as child
    if (!_isChildLoggedIn()) {
      AppLogger.warning(
        'ChildBloc: Skipping postDeviceInfo - not logged in as child',
      );
      _stopDeviceInfoTimer();
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, stopping device info timer',
        );
        _stopDeviceInfoTimer();
        return;
      }

      final requestBody = {
        "child_id": childId,
        "battery_percentage": event.deviceInfo.batteryPercentage,
        "network_status": event.deviceInfo.networkStatus,
        "network_type": event.deviceInfo.networkType,
        "sound_profile": event.deviceInfo.soundProfile,
        "is_online": event.deviceInfo.isOnline,
        "timestamp": DateTime.now().toIso8601String(),
      };
      await _childRepo.postChildData(requestBody);
    } catch (e) {
      AppLogger.error('Failed to post device info: ${e.toString()}');
    } finally {
      // Only start timer if still logged in as child
      if (_isChildLoggedIn()) {
        _startDeviceInfoTimer();
      }
    }
  }

  Future<void> _onGetScreenTime(
    GetScreenTime event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;
    try {
      final installedApps = await _deviceInfoService.getInstalledApps();
      final screenTimeUsage = await _deviceInfoService.getScreenTime();

      // Create a map of usage data for quick lookup
      final usageMap = {
        for (var app in screenTimeUsage) app.package: app.seconds,
      };

      // Merge installed apps with usage data
      final List<AppScreenTimeModel> mergedScreenTime = [];

      for (var app in installedApps) {
        final seconds = usageMap[app.packageName] ?? 0;
        mergedScreenTime.add(
          AppScreenTimeModel(
            package: app.packageName,
            appName: app.appName,
            isSystemApp: app.isSystemApp,
            seconds: seconds,
          ),
        );

        // Remove from usageMap to identify apps with usage but not in installed list
        usageMap.remove(app.packageName);
      }

      // Add remaining apps from usageMap (apps with usage but somehow not in installed list)
      usageMap.forEach((package, seconds) {
        // Find if we have partial info in screenTimeUsage list
        final originalUsage = screenTimeUsage.firstWhere(
          (element) => element.package == package,
          orElse: () => AppScreenTimeModel(package: package, seconds: seconds),
        );

        mergedScreenTime.add(
          AppScreenTimeModel(
            package: package,
            appName: originalUsage.appName.isNotEmpty
                ? originalUsage.appName
                : package, // Fallback to package name
            isSystemApp: originalUsage.isSystemApp,
            seconds: seconds,
          ),
        );
      });

      emit(currentState.copyWith(screenTime: mergedScreenTime));
      add(PostScreenTime(appScreenTimes: mergedScreenTime));
    } catch (e) {
      AppLogger.error('Failed to get screen time: ${e.toString()}');
    }
  }

  Future<void> _onPostScreenTime(
    PostScreenTime event,
    Emitter<ChildState> emit,
  ) async {
    // Check if user is still logged in as child
    if (!_isChildLoggedIn()) {
      AppLogger.warning(
        'ChildBloc: Skipping postScreenTime - not logged in as child',
      );
      _stopScreenTimeTimer();
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, stopping screen time timer',
        );
        _stopScreenTimeTimer();
        return;
      }

      final requestBody = {
        "child_id": childId,
        "date": DateTime.now().toIso8601String().split('T')[0],
        "total_seconds": event.appScreenTimes.fold(
          0,
          (sum, app) => sum + app.seconds,
        ),
        "apps": event.appScreenTimes.map((app) => app.toJson()).toList(),
      };
      await _childRepo.postScreenTime(requestBody);
    } catch (e) {
      AppLogger.error('Failed to post screen time: ${e.toString()}');
    } finally {
      // Only start timer if still logged in as child
      if (_isChildLoggedIn()) {
        _startScreenTimeTimer();
      }
    }
  }

  Future<void> _onGetChildLocation(
    GetChildLocation event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;
    try {
      final location = await _childLocationRepo.getChildLocation();
      if (location != null) {
        final previousLocation = currentState.childLocation;

        // Check if child moved 10m or more (and not already tracking a trip)
        if (previousLocation != null && !currentState.isTripTracking) {
          final distance = await _childLocationRepo.getDistanceBetweenTwoPoints(
            previousLocation,
            location,
          );

          // If moved 10m or more, automatically start trip tracking
          if (distance >= 10.0) {
            add(StartTripTracking());
            return; // StartTripTracking will handle the location update
          }
        }

        emit(currentState.copyWith(childLocation: location));
        add(PostChildLocation(childLocation: location));
      }
    } catch (e) {
      AppLogger.error('Failed to get child location: ${e.toString()}');
    }
  }

  Future<void> _onPostChildLocation(
    PostChildLocation event,
    Emitter<ChildState> emit,
  ) async {
    // Check if user is still logged in as child
    if (!_isChildLoggedIn()) {
      AppLogger.warning(
        'ChildBloc: Skipping postChildLocation - not logged in as child',
      );
      _stopChildLocationTimer();
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, stopping location timer',
        );
        _stopChildLocationTimer();
        return;
      }

      // Get dynamic address and place name from coordinates
      final locationInfo = await _childLocationRepo.getAddressAndPlaceName(
        event.childLocation.latitude,
        event.childLocation.longitude,
      );

      final requestBody = {
        "address": locationInfo?['address'] ?? 'Unknown',
        "place_name": locationInfo?['place_name'] ?? 'Unknown',
        "child_id": childId,
        "lat": event.childLocation.latitude,
        "lng": event.childLocation.longitude,
        "accuracy_m": event.childLocation.accuracy,
        "speed_mps": event.childLocation.speed,
        "bearing": event.childLocation.heading,
        "timestamp": DateTime.now().toIso8601String(),
      };
      await _childRepo.postChildLocation(requestBody);
    } catch (e) {
      AppLogger.error('Failed to post child location: ${e.toString()}');
    } finally {
      // Only start timer if still logged in as child
      if (_isChildLoggedIn()) {
        _startChildLocationTimer();
      }
    }
  }

  void _startDeviceInfoTimer() {
    _stopDeviceInfoTimer();
    _deviceInfoTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (isClosed || !_isChildLoggedIn()) {
        timer.cancel();
        return;
      }
      add(LoadDeviceInfo());
    });
  }

  void _stopDeviceInfoTimer() {
    _deviceInfoTimer?.cancel();
    _deviceInfoTimer = null;
  }

  void _startScreenTimeTimer() {
    _stopScreenTimeTimer();
    _screenTimeTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (isClosed || !_isChildLoggedIn()) {
        timer.cancel();
        return;
      }
      final currentState = state;
      if (currentState is ChildDeviceInfoLoaded) {
        add(GetScreenTime());
      }
    });
  }

  void _stopScreenTimeTimer() {
    _screenTimeTimer?.cancel();
    _screenTimeTimer = null;
  }

  void _stopChildLocationTimer() {
    _childLocationTimer?.cancel();
    _childLocationTimer = null;
  }

  void _startChildLocationTimer() {
    _stopChildLocationTimer();
    _childLocationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isClosed || !_isChildLoggedIn()) {
        timer.cancel();
        return;
      }
      add(GetChildLocation());
    });
  }

  Future<void> _onStartTripTracking(
    StartTripTracking event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;

    // Get initial location
    try {
      final location = await _childLocationRepo.getChildLocation();
      if (location != null) {
        final now = DateTime.now();
        emit(
          currentState.copyWith(
            isTripTracking: true,
            tripStartTime: now,
            tripLocations: [location],
            lastTrackedLocation: location,
            childLocation: location,
          ),
        );

        // Start trip location tracking timer (every 5 seconds)
        _startTripLocationTimer();
      }
    } catch (e) {
      AppLogger.error('Failed to start trip tracking: ${e.toString()}');
    }
  }

  Future<void> _onStopTripTracking(
    StopTripTracking event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded ||
        !currentState.isTripTracking) {
      return;
    }

    _stopTripLocationTimer();

    // Post trip event if we have trip data
    if (currentState.tripLocations.isNotEmpty &&
        currentState.tripStartTime != null) {
      await _postTripEvent(currentState, emit);
    }

    // Reset trip tracking state
    emit(
      currentState.copyWith(
        isTripTracking: false,
        tripLocations: [],
        tripStartTime: null,
        lastTrackedLocation: null,
      ),
    );
  }

  Future<void> _onUpdateTripLocation(
    UpdateTripLocation event,
    Emitter<ChildState> emit,
  ) async {
    // Check if user is still logged in as child
    if (!_isChildLoggedIn()) {
      AppLogger.warning(
        'ChildBloc: Skipping updateTripLocation - not logged in as child',
      );
      _stopTripLocationTimer();
      return;
    }

    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded ||
        !currentState.isTripTracking) {
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, stopping trip tracking',
        );
        _stopTripLocationTimer();
        return;
      }

      final newLocation = event.location;
      final lastLocation = currentState.lastTrackedLocation;

      // Check if child moved 10m or more from last tracked location
      bool shouldTrack = true;
      if (lastLocation != null) {
        final distance = await _childLocationRepo.getDistanceBetweenTwoPoints(
          lastLocation,
          newLocation,
        );
        shouldTrack = distance >= 10.0; // 10 meters
      }

      if (shouldTrack) {
        // Update state with new location
        final updatedLocations = [...currentState.tripLocations, newLocation];
        emit(
          currentState.copyWith(
            tripLocations: updatedLocations,
            lastTrackedLocation: newLocation,
            childLocation: newLocation,
          ),
        );

        // Get dynamic address and place name from coordinates
        final locationInfo = await _childLocationRepo.getAddressAndPlaceName(
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
        await _childRepo.postChildLocation(requestBody);
      }
    } catch (e) {
      AppLogger.error('Failed to update trip location: ${e.toString()}');
    }
  }

  void _startTripLocationTimer() {
    _stopTripLocationTimer();
    _tripLocationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isClosed || !_isChildLoggedIn()) {
        timer.cancel();
        return;
      }
      final currentState = state;
      if (currentState is! ChildDeviceInfoLoaded ||
          !currentState.isTripTracking) {
        _stopTripLocationTimer();
        return;
      }

      // Get current location and update trip
      _childLocationRepo
          .getChildLocation()
          .then((location) {
            if (location != null && !isClosed && _isChildLoggedIn()) {
              add(UpdateTripLocation(location: location));
            }
          })
          .catchError((e) {
            AppLogger.error('Failed to get location for trip tracking: $e');
          });
    });
  }

  void _stopTripLocationTimer() {
    _tripLocationTimer?.cancel();
    _tripLocationTimer = null;
  }

  Future<void> _postTripEvent(
    ChildDeviceInfoLoaded state,
    Emitter<ChildState> emit,
  ) async {
    // Check if user is still logged in as child
    if (!_isChildLoggedIn()) {
      AppLogger.warning(
        'ChildBloc: Skipping postTripEvent - not logged in as child',
      );
      return;
    }

    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) {
        AppLogger.warning(
          'ChildBloc: child_id is null, cannot post trip event',
        );
        return;
      }

      if (state.tripLocations.length < 2 || state.tripStartTime == null) {
        return;
      }

      final startLocation = state.tripLocations.first;
      final endLocation = state.tripLocations.last;
      final endTime = DateTime.now();
      final duration = endTime.difference(state.tripStartTime!);

      // Get dynamic address and place name for start and end locations
      final startLocationInfo = await _childLocationRepo.getAddressAndPlaceName(
        startLocation.latitude,
        startLocation.longitude,
      );
      final endLocationInfo = await _childLocationRepo.getAddressAndPlaceName(
        endLocation.latitude,
        endLocation.longitude,
      );

      // Calculate distance (sum of distances between consecutive points)
      double totalDistance = 0.0;
      double maxSpeed = 0.0;

      for (int i = 0; i < state.tripLocations.length - 1; i++) {
        final distance = await _childLocationRepo.getDistanceBetweenTwoPoints(
          state.tripLocations[i],
          state.tripLocations[i + 1],
        );
        totalDistance += distance;

        // Track max speed (convert m/s to km/h)
        final speed = state.tripLocations[i].speed * 3.6;
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
        "start_time": state.tripStartTime!.toIso8601String(),
        "end_time": endTime.toIso8601String(),
      };

      await _childRepo.postTripEvent(requestBody);
      AppLogger.info('Trip event posted successfully');
    } catch (e) {
      AppLogger.error('Failed to post trip event: ${e.toString()}');
    }
  }

  @override
  Future<void> close() {
    _stopDeviceInfoTimer();
    _stopScreenTimeTimer();
    _stopChildLocationTimer();
    _stopTripLocationTimer();
    return super.close();
  }
}

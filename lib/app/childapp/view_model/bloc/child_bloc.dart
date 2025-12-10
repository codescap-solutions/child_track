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
    add(LoadDeviceInfo());
    add(GetScreenTime());
    add(GetChildLocation());
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
    try {
      final requestBody = {
        "child_id": "_sharedPrefsService.getString('child_id')",
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
      _startDeviceInfoTimer();
    }
  }

  Future<void> _onGetScreenTime(
    GetScreenTime event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;
    try {
      final screenTime = await _deviceInfoService.getScreenTime();
      emit(currentState.copyWith(screenTime: screenTime));
      add(PostScreenTime(appScreenTimes: screenTime));
    } catch (e) {
      AppLogger.error('Failed to get screen time: ${e.toString()}');
    }
  }

  Future<void> _onPostScreenTime(
    PostScreenTime event,
    Emitter<ChildState> emit,
  ) async {
    try {
      final requestBody = {
        "child_id": "_sharedPrefsService.getString('child_id')",
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
      _startScreenTimeTimer();
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
    try {
      // Get dynamic address and place name from coordinates
      final locationInfo = await _childLocationRepo.getAddressAndPlaceName(
        event.childLocation.latitude,
        event.childLocation.longitude,
      );

      final requestBody = {
        "address": locationInfo?['address'] ?? 'Unknown',
        "place_name": locationInfo?['place_name'] ?? 'Unknown',
        "child_id": _sharedPrefsService.getString('child_id'),
     
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
      _startChildLocationTimer();
    }
  }

  void _startDeviceInfoTimer() {
    _stopDeviceInfoTimer();
    _deviceInfoTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
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
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded ||
        !currentState.isTripTracking) {
      return;
    }

    try {
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
          "child_id": "_sharedPrefsService.getString('child_id')",
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
            if (location != null) {
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
    try {
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
        "child_id": "_sharedPrefsService.getString('child_id')",
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

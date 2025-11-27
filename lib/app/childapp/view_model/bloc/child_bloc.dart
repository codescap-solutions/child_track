import 'dart:async';
import 'package:child_track/app/childapp/model/scree_time_model.dart';
import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
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
  // Timers
  Timer? _deviceInfoTimer; // 10 minutes
  Timer? _screenTimeTimer; // 1 hour
  Timer? _childLocationTimer; // 30 seconds
  ChildBloc({
    required ChildInfoService deviceInfoService,
    required ChildRepo childRepo,
    required ChildGoogleMapsRepo childLocationRepo,
  }) : _deviceInfoService = deviceInfoService,
       _childRepo = childRepo,
       _childLocationRepo = childLocationRepo,
       super(ChildDeviceInfoLoaded.initial()) {
    on<LoadDeviceInfo>(_onLoadDeviceInfo);
    on<PostDeviceInfo>(_onPostDeviceInfo);
    on<GetScreenTime>(_onGetScreenTime);
    on<PostScreenTime>(_onPostScreenTime);
    on<GetChildLocation>(_onGetChildLocation);
    on<PostChildLocation>(_onPostChildLocation);
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
        "child_id": "uuid",
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
        "child_id": "uuid",
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
      final requestBody = {
        "child_id": "uuid",
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

  @override
  Future<void> close() {
    _stopDeviceInfoTimer();
    _stopScreenTimeTimer();
    _stopChildLocationTimer();
    return super.close();
  }
}

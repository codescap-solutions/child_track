import 'dart:async';
import 'package:child_track/app/childapp/model/scree_time_model.dart';
import 'package:child_track/app/childapp/view_model/child_repo.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/app/childapp/view_model/device_info_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'child_event.dart';
part 'child_state.dart';

class ChildBloc extends Bloc<SosEvent, SosState> {
  final ChildInfoService _deviceInfoService;
  final ChildRepo _sosRepo;
  // device info timer
  Timer? _deviceInfoTimer;
  Timer? _screenTimeTimer;
  ChildBloc({
    required ChildInfoService deviceInfoService,
    required ChildRepo sosRepo,
  }) : _deviceInfoService = deviceInfoService,
       _sosRepo = sosRepo,
       super(SosDeviceInfoLoaded.initial()) {
    on<LoadDeviceInfo>(_onLoadDeviceInfo);
    on<PostDeviceInfo>(_onPostDeviceInfo);
    on<GetScreenTime>(_onGetScreenTime);
    on<PostScreenTime>(_onPostScreenTime);
  }

  Future<void> _onLoadDeviceInfo(
    LoadDeviceInfo event,
    Emitter<SosState> emit,
  ) async {
    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      emit(SosDeviceInfoLoaded(deviceInfo: deviceInfo));
      add(PostDeviceInfo(deviceInfo: deviceInfo));
    } catch (e) {
      AppLogger.error('Failed to load device info: ${e.toString()}');
    }
  }

  Future<void> _onPostDeviceInfo(
    PostDeviceInfo event,
    Emitter<SosState> emit,
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
      await _sosRepo.postChildData(requestBody);
    } catch (e) {
      AppLogger.error('Failed to post device info: ${e.toString()}');
    } finally {
      _startDeviceInfoTimer();
    }
  }

  Future<void> _onGetScreenTime(
    GetScreenTime event,
    Emitter<SosState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SosDeviceInfoLoaded) return;
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
    Emitter<SosState> emit,
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
      await _sosRepo.postScreenTime(requestBody);
    } catch (e) {
      AppLogger.error('Failed to post screen time: ${e.toString()}');
    } finally {
      _startScreenTimeTimer();
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
      if (currentState is SosDeviceInfoLoaded) {
        add(GetScreenTime());
      }
    });
  }

  void _stopScreenTimeTimer() {
    _screenTimeTimer?.cancel();
    _screenTimeTimer = null;
  }

  @override
  Future<void> close() {
    _stopDeviceInfoTimer();
    _stopScreenTimeTimer();
    return super.close();
  }
}

import 'dart:async';
import 'package:child_track/app/childapp/model/scree_time_model.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'package:child_track/core/services/firebase_notification_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/screen_time_sync_service.dart';
import 'package:child_track/core/services/background_task_service.dart';
part 'child_event.dart';
part 'child_state.dart';

/// ChildBloc — handles device info and screen time ONLY.
///
/// Location tracking and trip detection are handled exclusively by
/// the foreground service (BackgroundLocationService + LocationBatchUploader).
/// This eliminates the dual-posting architecture that caused duplicates
/// and conflicting trip states.
class ChildBloc extends Bloc<ChildEvent, ChildState> {
  final ChildInfoService _deviceInfoService;
  final ChildRepo _childRepo;
  final SharedPrefsService _sharedPrefsService;
  final ScreenTimeSyncService _screenTimeSyncService;

  ChildBloc({
    required ChildRepo childRepo,
    required SharedPrefsService sharedPrefsService,
    required ChildInfoService deviceInfoService,
    required ScreenTimeSyncService screenTimeSyncService,
  }) : _deviceInfoService = deviceInfoService,
       _childRepo = childRepo,
       _sharedPrefsService = sharedPrefsService,
       _screenTimeSyncService = screenTimeSyncService,
       super(ChildDeviceInfoLoaded.initial()) {
    on<LoadDeviceInfo>(_onLoadDeviceInfo);
    on<PostDeviceInfo>(_onPostDeviceInfo);
    on<GetScreenTime>(_onGetScreenTime);
    on<PostScreenTime>(_onPostScreenTime);
    on<OpenUsageSettings>(_onOpenUsageSettings);
    on<CheckUsagePermission>(_onCheckUsagePermission);
  }

  void onInitialize() {
    final childId = _sharedPrefsService.getString('child_id');
    final parentId = _sharedPrefsService.getString('parent_id');

    if (childId != null &&
        childId.isNotEmpty &&
        (parentId == null || parentId.isEmpty)) {
      AppLogger.info('ChildBloc: Initializing for child_id: $childId');
      add(LoadDeviceInfo());
      add(CheckUsagePermission());

      // Schedule background sync for screen time
      BackgroundTaskService.schedulePeriodicSync();

      // Register FCM token
      FirebaseNotificationService().registerTokenWithServer();
    } else {
      AppLogger.info(
        'ChildBloc: Skipping initialization - not logged in as child',
      );
    }
  }

  // ── Device Info ─────────────────────────────────────────────────────

  Future<void> _onLoadDeviceInfo(
    LoadDeviceInfo event,
    Emitter<ChildState> emit,
  ) async {
    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      final currentState = state;
      if (currentState is ChildDeviceInfoLoaded) {
        emit(currentState.copyWith(deviceInfo: deviceInfo));
      } else {
        emit(ChildDeviceInfoLoaded(deviceInfo: deviceInfo));
      }
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
      final childId = _sharedPrefsService.getString('child_id');
      final requestBody = {
        "child_id": childId,
        "battery_percentage": event.deviceInfo.batteryPercentage,
        "network_status": event.deviceInfo.networkStatus,
        "network_type": event.deviceInfo.networkType,
        "sound_profile": event.deviceInfo.soundProfile,
        "is_online": event.deviceInfo.isOnline,
        "timestamp": DateTime.now().toUtc().toIso8601String(),
      };
      await _childRepo.postChildData(requestBody);
    } catch (e) {
      AppLogger.error('Failed to post device info: ${e.toString()}');
    }
  }

  // ── Screen Time ─────────────────────────────────────────────────────

  Future<void> _onCheckUsagePermission(
    CheckUsagePermission event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;

    AppLogger.info('ChildBloc: Checking usage permission...');
    final hasPermission = await _deviceInfoService.checkUsagePermission();
    AppLogger.info('ChildBloc: Usage permission result: $hasPermission');
    emit(currentState.copyWith(hasUsagePermission: hasPermission));
    if (hasPermission) {
      add(GetScreenTime());
    }
  }

  Future<void> _onGetScreenTime(
    GetScreenTime event,
    Emitter<ChildState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChildDeviceInfoLoaded) return;

    if (!currentState.hasUsagePermission) {
      final hasPermission = await _deviceInfoService.checkUsagePermission();
      if (!hasPermission) {
        emit(currentState.copyWith(hasUsagePermission: false, screenTime: []));
        return;
      }
      emit(currentState.copyWith(hasUsagePermission: true));
    }

    try {
      final mergedScreenTime = await _screenTimeSyncService
          .fetchScreenTimeData();
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
    try {
      final childId = _sharedPrefsService.getString('child_id');
      if (childId == null || childId.isEmpty) return;

      await _screenTimeSyncService.uploadScreenTimeData(
        event.appScreenTimes,
        childId,
      );
    } catch (e) {
      AppLogger.error('Failed to post screen time: ${e.toString()}');
    }
  }

  Future<void> _onOpenUsageSettings(
    OpenUsageSettings event,
    Emitter<ChildState> emit,
  ) async {
    await _deviceInfoService.openUsageSettings();
  }

  // ── Cleanup ─────────────────────────────────────────────────────────

  void stopChildTracking() {
    BackgroundTaskService.cancelAll();
  }
}

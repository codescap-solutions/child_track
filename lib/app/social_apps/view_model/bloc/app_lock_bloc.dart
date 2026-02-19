import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:child_track/core/services/lock_sync_service.dart';
import 'package:child_track/core/utils/app_logger.dart';
import 'app_lock_event.dart';
import 'app_lock_state.dart';

class AppLockBloc extends Bloc<AppLockEvent, AppLockState> {
  final LockSyncService _lockSyncService;
  final Map<String, Timer> _unlockTimers = {};

  AppLockBloc({required LockSyncService lockSyncService})
    : _lockSyncService = lockSyncService,
      super(AppLockInitial()) {
    on<CheckAccessibilityPermission>(_onCheckAccessibilityPermission);
    on<OpenAccessibilitySettings>(_onOpenAccessibilitySettings);
    on<ToggleAppLock>(_onToggleAppLock);
    on<UpdateLockedApps>(_onUpdateLockedApps);
  }

  Future<void> _onCheckAccessibilityPermission(
    CheckAccessibilityPermission event,
    Emitter<AppLockState> emit,
  ) async {
    final hasPermission = await _lockSyncService.checkAccessibilityPermission();
    if (state is AppLockLoaded) {
      emit(
        (state as AppLockLoaded).copyWith(
          hasAccessibilityPermission: hasPermission,
        ),
      );
    } else {
      emit(AppLockLoaded(hasAccessibilityPermission: hasPermission));
    }
  }

  Future<void> _onOpenAccessibilitySettings(
    OpenAccessibilitySettings event,
    Emitter<AppLockState> emit,
  ) async {
    await _lockSyncService.openAccessibilitySettings();
    // Re-check permission after returning from settings (handled by lifecycle observer in UI usually)
    // but we can also emit a loading state or similar if needed.
    // For now, we trust the UI to poll or check on resume.
  }

  Future<void> _onToggleAppLock(
    ToggleAppLock event,
    Emitter<AppLockState> emit,
  ) async {
    final currentState = state is AppLockLoaded
        ? state as AppLockLoaded
        : const AppLockLoaded();

    final newLockedPackages = Set<String>.from(currentState.lockedPackages);

    if (event.isLocked) {
      newLockedPackages.add(event.packageName);

      // Handle timer if duration > 0
      _unlockTimers[event.packageName]?.cancel(); // Cancel existing
      if (event.durationMinutes > 0) {
        AppLogger.info(
          'Locking ${event.packageName} for ${event.durationMinutes} minutes',
        );
        _unlockTimers[event.packageName] = Timer(
          Duration(minutes: event.durationMinutes),
          () {
            add(ToggleAppLock(packageName: event.packageName, isLocked: false));
          },
        );
      }
    } else {
      newLockedPackages.remove(event.packageName);
      _unlockTimers[event.packageName]?.cancel();
      _unlockTimers.remove(event.packageName);
    }

    // Update state
    emit(currentState.copyWith(lockedPackages: newLockedPackages));

    // Sync to native
    await _lockSyncService.syncLockedAppsToNative(newLockedPackages.toList());

    // Check permission if logic requires
    if (state is! AppLockLoaded) {
      add(CheckAccessibilityPermission());
    }
  }

  Future<void> _onUpdateLockedApps(
    UpdateLockedApps event,
    Emitter<AppLockState> emit,
  ) async {
    final newSet = event.lockedPackages.toSet();
    if (state is AppLockLoaded) {
      emit((state as AppLockLoaded).copyWith(lockedPackages: newSet));
    } else {
      emit(AppLockLoaded(lockedPackages: newSet));
      add(CheckAccessibilityPermission());
    }
    await _lockSyncService.syncLockedAppsToNative(event.lockedPackages);
  }
}

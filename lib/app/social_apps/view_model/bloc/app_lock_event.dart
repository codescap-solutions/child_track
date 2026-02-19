import 'package:equatable/equatable.dart';

abstract class AppLockEvent extends Equatable {
  const AppLockEvent();

  @override
  List<Object> get props => [];
}

class CheckAccessibilityPermission extends AppLockEvent {}

class OpenAccessibilitySettings extends AppLockEvent {}

class ToggleAppLock extends AppLockEvent {
  final String packageName;
  final bool isLocked;
  final int durationMinutes;

  const ToggleAppLock({
    required this.packageName,
    required this.isLocked,
    this.durationMinutes = 0,
  });

  @override
  List<Object> get props => [packageName, isLocked, durationMinutes];
}

class UpdateLockedApps extends AppLockEvent {
  final List<String> lockedPackages;

  const UpdateLockedApps(this.lockedPackages);

  @override
  List<Object> get props => [lockedPackages];
}

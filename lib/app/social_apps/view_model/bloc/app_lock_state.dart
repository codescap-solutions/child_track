import 'package:equatable/equatable.dart';

abstract class AppLockState extends Equatable {
  const AppLockState();

  @override
  List<Object> get props => [];
}

class AppLockInitial extends AppLockState {}

class AppLockLoading extends AppLockState {}

class AppLockLoaded extends AppLockState {
  final Set<String> lockedPackages;
  final bool hasAccessibilityPermission;

  const AppLockLoaded({
    this.lockedPackages = const {},
    this.hasAccessibilityPermission = false,
  });

  AppLockLoaded copyWith({
    Set<String>? lockedPackages,
    bool? hasAccessibilityPermission,
  }) {
    return AppLockLoaded(
      lockedPackages: lockedPackages ?? this.lockedPackages,
      hasAccessibilityPermission:
          hasAccessibilityPermission ?? this.hasAccessibilityPermission,
    );
  }

  @override
  List<Object> get props => [lockedPackages, hasAccessibilityPermission];
}

class AppLockError extends AppLockState {
  final String message;

  const AppLockError(this.message);

  @override
  List<Object> get props => [message];
}

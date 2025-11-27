part of 'sos_bloc.dart';

sealed class SosState extends Equatable {
  const SosState();

  @override
  List<Object> get props => [];
}

final class SosInitial extends SosState {}

final class SosLoading extends SosState {}

final class SosDeviceInfoLoaded extends SosState {
  final DeviceInfo deviceInfo;

  const SosDeviceInfoLoaded({
    required this.deviceInfo,
  });

  @override
  List<Object> get props => [deviceInfo];

  SosDeviceInfoLoaded copyWith({
    DeviceInfo? deviceInfo,
  }) {
    return SosDeviceInfoLoaded(
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}

final class SosError extends SosState {
  final String message;

  const SosError({required this.message});

  @override
  List<Object> get props => [message];
}


part of 'child_bloc.dart';

sealed class SosState extends Equatable {
  const SosState();

  @override
  List<Object> get props => [];
}

final class SosDeviceInfoLoaded extends SosState {
  final DeviceInfo deviceInfo;
  final List<AppScreenTimeModel> screenTime;

  const SosDeviceInfoLoaded({
    required this.deviceInfo,
    this.screenTime = const [],
  });

  @override
  List<Object> get props => [deviceInfo, screenTime];

  SosDeviceInfoLoaded copyWith({
    DeviceInfo? deviceInfo,
    List<AppScreenTimeModel>? screenTime,
  }) {
    return SosDeviceInfoLoaded(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      screenTime: screenTime ?? this.screenTime,
    );
  }

  static SosDeviceInfoLoaded initial() {
    return SosDeviceInfoLoaded(
      deviceInfo: DeviceInfo(
        batteryPercentage: 0,
        networkStatus: '',
        networkType: '',
        soundProfile: '',
        isOnline: false,
        onlineSince: '',
      ),
      screenTime: [],
    );
  }
}

final class SosError extends SosState {
  final String message;

  const SosError({required this.message});

  @override
  List<Object> get props => [message];
}

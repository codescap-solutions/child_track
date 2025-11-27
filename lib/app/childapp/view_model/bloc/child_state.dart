part of 'child_bloc.dart';

sealed class ChildState extends Equatable {
  const ChildState();

  @override
  List<Object> get props => [];
}

final class ChildDeviceInfoLoaded extends ChildState {
  final DeviceInfo deviceInfo;
  final List<AppScreenTimeModel> screenTime;
  final Position? childLocation;
  const ChildDeviceInfoLoaded({
    required this.deviceInfo,
    this.screenTime = const [],
    this.childLocation,
  });

  @override
  List<Object> get props => [deviceInfo, screenTime, ?childLocation];

  ChildDeviceInfoLoaded copyWith({
    DeviceInfo? deviceInfo,
    List<AppScreenTimeModel>? screenTime,
    Position? childLocation,
  }) {
    return ChildDeviceInfoLoaded(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      screenTime: screenTime ?? this.screenTime,
      childLocation: childLocation ?? this.childLocation,
    );
  }

  static ChildDeviceInfoLoaded initial() {
    return ChildDeviceInfoLoaded(
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

final class SosError extends ChildState {
  final String message;

  const SosError({required this.message});

  @override
  List<Object> get props => [message];
}

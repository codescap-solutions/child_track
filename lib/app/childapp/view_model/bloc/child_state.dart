part of 'child_bloc.dart';

sealed class ChildState extends Equatable {
  const ChildState();

  @override
  List<Object> get props => [];
}

final class ChildDeviceInfoLoaded extends ChildState {
  final DeviceInfo deviceInfo;
  final List<AppScreenTimeModel> screenTime;
  final bool hasUsagePermission;

  const ChildDeviceInfoLoaded({
    required this.deviceInfo,
    this.screenTime = const [],
    this.hasUsagePermission = false,
  });

  @override
  List<Object> get props => [deviceInfo, screenTime, hasUsagePermission];

  ChildDeviceInfoLoaded copyWith({
    DeviceInfo? deviceInfo,
    List<AppScreenTimeModel>? screenTime,
    bool? hasUsagePermission,
  }) {
    return ChildDeviceInfoLoaded(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      screenTime: screenTime ?? this.screenTime,
      hasUsagePermission: hasUsagePermission ?? this.hasUsagePermission,
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
      hasUsagePermission: false,
    );
  }
}

final class SosError extends ChildState {
  final String message;

  const SosError({required this.message});

  @override
  List<Object> get props => [message];
}

part of 'child_bloc.dart';

sealed class SosEvent extends Equatable {
  const SosEvent();

  @override
  List<Object> get props => [];
}

final class LoadDeviceInfo extends SosEvent {}

final class PostDeviceInfo extends SosEvent {
  final DeviceInfo deviceInfo;

  const PostDeviceInfo({required this.deviceInfo});

  @override
  List<Object> get props => [deviceInfo];
}
final class GetScreenTime extends SosEvent {}

final class PostScreenTime extends SosEvent {
  final List<AppScreenTimeModel> appScreenTimes;
  const PostScreenTime({required this.appScreenTimes});
  @override
  List<Object> get props => [];
}

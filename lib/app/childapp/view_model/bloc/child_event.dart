part of 'child_bloc.dart';

sealed class ChildEvent extends Equatable {
  const ChildEvent();

  @override
  List<Object> get props => [];
}

final class LoadDeviceInfo extends ChildEvent {}

final class PostDeviceInfo extends ChildEvent {
  final DeviceInfo deviceInfo;

  const PostDeviceInfo({required this.deviceInfo});

  @override
  List<Object> get props => [deviceInfo];
}

final class GetScreenTime extends ChildEvent {}

final class PostScreenTime extends ChildEvent {
  final List<AppScreenTimeModel> appScreenTimes;
  const PostScreenTime({required this.appScreenTimes});
  @override
  List<Object> get props => [];
}

final class GetChildLocation extends ChildEvent {}

final class PostChildLocation extends ChildEvent {
  final Position childLocation;
  const PostChildLocation({required this.childLocation});
  @override
  List<Object> get props => [childLocation];
}

part of 'homepage_bloc.dart';

sealed class HomepageEvent extends Equatable {
  const HomepageEvent();

  @override
  List<Object> get props => [];
}

final class GetHomepageData extends HomepageEvent {
  final bool isSilentRefresh;
  final bool isProgressFetching;

  const GetHomepageData({
    this.isSilentRefresh = false,
    this.isProgressFetching = false,
  });

  @override
  List<Object> get props => [isSilentRefresh, isProgressFetching];
}

final class GetTrips extends HomepageEvent {
  final int? page;
  final int? pageSize;

  const GetTrips({this.page, this.pageSize});

  @override
  List<Object> get props => [
    if (page != null) page!,
    if (pageSize != null) pageSize!,
  ];
}

final class GetTripDetail extends HomepageEvent {
  final String tripId;

  const GetTripDetail({required this.tripId});

  @override
  List<Object> get props => [tripId];
}

final class UpdateSocketLocation extends HomepageEvent {
  final Map<String, dynamic> locationData;

  const UpdateSocketLocation(this.locationData);

  @override
  List<Object> get props => [locationData];
}
final class UpdateSocketStatus extends HomepageEvent {
  final Map<String, dynamic> statusData;

  const UpdateSocketStatus(this.statusData);

  @override
  List<Object> get props => [statusData];
}

final class UpdateCurrentLocationName extends HomepageEvent {
  final String newName;

  const UpdateCurrentLocationName(this.newName);

  @override
  List<Object> get props => [newName];
}

/// Lightweight periodic refresh of just the tracking snapshot (device/GPS
/// status, staleness banner) — deliberately does not touch trips, home data,
/// or loading flags, so it can run on a short timer without disrupting the UI.
final class RefreshTrackingSnapshot extends HomepageEvent {
  const RefreshTrackingSnapshot();
}

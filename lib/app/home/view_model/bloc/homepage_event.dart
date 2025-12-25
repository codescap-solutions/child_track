part of 'homepage_bloc.dart';

sealed class HomepageEvent extends Equatable {
  const HomepageEvent();

  @override
  List<Object> get props => [];
}

final class GetHomepageData extends HomepageEvent {
  // final String? childId;

  // const GetHomepageData({this.childId});

  // @override
  // List<Object> get props => [if (childId != null) childId!];
}

final class FetchChildCurrentDetails extends HomepageEvent {}

final class GetTrips extends HomepageEvent {
  // final String? childId;
  final int? page;
  final int? pageSize;

  const GetTrips({
    // this.childId,
    this.page,
    this.pageSize,
  });

  @override
  List<Object> get props => [
    // if (childId != null) childId!,
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

final class UpdateSocketTrip extends HomepageEvent {
  final Map<String, dynamic> tripData;

  const UpdateSocketTrip(this.tripData);

  @override
  List<Object> get props => [tripData];
}

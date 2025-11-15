part of 'homepage_bloc.dart';

sealed class HomepageEvent extends Equatable {
  const HomepageEvent();

  @override
  List<Object> get props => [];
}

final class GetHomepageData extends HomepageEvent {}

// Map-related events
final class InitializeMap extends HomepageEvent {}

final class MapCreated extends HomepageEvent {
  final GoogleMapController controller;
  const MapCreated(this.controller);

  @override
  List<Object> get props => [controller];
}

final class MoveToCurrentLocation extends HomepageEvent {}

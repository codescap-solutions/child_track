part of 'map_bloc.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class MapCreated extends MapEvent {
  final GoogleMapController controller;

  const MapCreated(this.controller);

  @override
  List<Object> get props => [controller];
}

class MarkerAdded extends MapEvent {
  final LatLng position;

  const MarkerAdded(this.position);

  @override
  List<Object> get props => [position];
}

class MarkerTapped extends MapEvent {
  final LatLng position;

  const MarkerTapped(this.position);

  @override
  List<Object> get props => [position];
}

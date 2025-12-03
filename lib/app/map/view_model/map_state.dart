part of 'map_bloc.dart';

sealed class MapState extends Equatable {
  const MapState();

  @override
  List<Object> get props => [];
}

final class MapInitial extends MapState {
  const MapInitial();
}

final class MapLoaded extends MapState {
  final List<Marker> markers;
  final Map<PolylineId, Polyline> polylines;
  final bool isLoading;
  final LatLng currentPosition;

  const MapLoaded({
    required this.markers,
    required this.polylines,
    this.isLoading = false,
    required this.currentPosition,
  });

  @override
  List<Object> get props => [markers, polylines, isLoading, currentPosition];

  MapLoaded copyWith({
    List<Marker>? markers,
    Map<PolylineId, Polyline>? polylines,
    bool? isLoading,
    LatLng? currentPosition,
  }) {
    return MapLoaded(
      currentPosition: currentPosition ?? this.currentPosition,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

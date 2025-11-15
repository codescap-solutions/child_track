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

  const MapLoaded({
    required this.markers,
    required this.polylines,
    this.isLoading = false,
  });

  @override
  List<Object> get props => [markers, polylines, isLoading];

  MapLoaded copyWith({
    List<Marker>? markers,
    Map<PolylineId, Polyline>? polylines,
    bool? isLoading,
  }) {
    return MapLoaded(
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

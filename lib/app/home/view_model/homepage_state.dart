part of 'homepage_bloc.dart';

// Sentinel object for null values in props
class _NullSentinel {
  const _NullSentinel();
}

const _nullSentinel = _NullSentinel();

sealed class HomepageState extends Equatable {
  const HomepageState();

  @override
  List<Object> get props => [];
}

final class HomepageInitial extends HomepageState {}

final class HomepageLoading extends HomepageState {}

final class HomepageSuccess extends HomepageState {}

final class HomepageError extends HomepageState {
  final String message;
  const HomepageError({required this.message});
  @override
  List<Object> get props => [message];
}

// Map-related states
final class MapInitial extends HomepageState {}

final class MapLoading extends HomepageState {}

final class MapLoaded extends HomepageState {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final BitmapDescriptor? kidMarkerIcon;
  final BitmapDescriptor? parentMarkerIcon;
  final GoogleMapController? mapController;

  const MapLoaded({
    this.currentPosition,
    required this.markers,
    this.polylines = const {},
    this.kidMarkerIcon,
    this.parentMarkerIcon,
    this.mapController,
  });

  @override
  List<Object> get props => [
    currentPosition ?? _nullSentinel,
    markers,
    polylines,
    kidMarkerIcon ?? _nullSentinel,
    parentMarkerIcon ?? _nullSentinel,
    mapController ?? _nullSentinel,
  ];

  MapLoaded copyWith({
    Position? currentPosition,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    BitmapDescriptor? kidMarkerIcon,
    BitmapDescriptor? parentMarkerIcon,
    GoogleMapController? mapController,
  }) {
    return MapLoaded(
      currentPosition: currentPosition ?? this.currentPosition,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
      kidMarkerIcon: kidMarkerIcon ?? this.kidMarkerIcon,
      parentMarkerIcon: parentMarkerIcon ?? this.parentMarkerIcon,
      mapController: mapController ?? this.mapController,
    );
  }
}

final class MapError extends HomepageState {
  final String message;
  const MapError({required this.message});
  @override
  List<Object> get props => [message];
}

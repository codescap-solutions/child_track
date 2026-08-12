import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../model/geofence_model.dart';

abstract class GeofenceState extends Equatable {
  const GeofenceState();

  @override
  List<Object?> get props => [];
}

class GeofenceInitial extends GeofenceState {
  const GeofenceInitial();
}

class GeofenceLoading extends GeofenceState {
  const GeofenceLoading();
}

class GeofencesLoaded extends GeofenceState {
  final List<Geofence> geofences;

  const GeofencesLoaded({required this.geofences});

  @override
  List<Object?> get props => [geofences];
}

class GeofenceCreated extends GeofenceState {
  final Geofence geofence;

  const GeofenceCreated({required this.geofence});

  @override
  List<Object?> get props => [geofence];
}

class GeofenceUpdated extends GeofenceState {
  final Geofence geofence;

  const GeofenceUpdated({required this.geofence});

  @override
  List<Object?> get props => [geofence];
}

class GeofenceDeleted extends GeofenceState {
  final String geofenceId;

  const GeofenceDeleted({required this.geofenceId});

  @override
  List<Object?> get props => [geofenceId];
}

class GeofenceLockToggled extends GeofenceState {
  final Geofence geofence;

  const GeofenceLockToggled({required this.geofence});

  @override
  List<Object?> get props => [geofence];
}

class LocationSuggestionsLoaded extends GeofenceState {
  final List<PlaceAutocompleteResult> suggestions;

  const LocationSuggestionsLoaded({required this.suggestions});

  @override
  List<Object?> get props => [suggestions];
}

class LocationSuggestionsCleared extends GeofenceState {
  const LocationSuggestionsCleared();
}

class PlaceCoordinatesLoaded extends GeofenceState {
  final LatLng coordinates;

  const PlaceCoordinatesLoaded({required this.coordinates});

  @override
  List<Object?> get props => [coordinates];
}

class GeofenceError extends GeofenceState {
  final String message;

  const GeofenceError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChildLocationLoaded extends GeofenceState {
  final LatLng coordinates;

  const ChildLocationLoaded({required this.coordinates});

  @override
  List<Object?> get props => [coordinates];
}

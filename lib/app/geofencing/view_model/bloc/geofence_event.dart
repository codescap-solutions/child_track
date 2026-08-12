import 'package:equatable/equatable.dart';

import '../../model/geofence_model.dart';

abstract class GeofenceEvent extends Equatable {
  const GeofenceEvent();

  @override
  List<Object?> get props => [];
}

class GeofenceInitializationRequested extends GeofenceEvent {
  const GeofenceInitializationRequested();
}

class GetGeofencesRequested extends GeofenceEvent {
  final String childId;
  final String? date;
  final String? startDate;
  final String? endDate;

  const GetGeofencesRequested({
    required this.childId,
    this.date,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [childId, date, startDate, endDate];
}

class CreateGeofenceRequested extends GeofenceEvent {
  final CreateGeofenceRequest request;

  const CreateGeofenceRequested({required this.request});

  @override
  List<Object?> get props => [request];
}

class UpdateGeofenceRequested extends GeofenceEvent {
  final String id;
  final UpdateGeofenceRequest request;

  const UpdateGeofenceRequested({required this.id, required this.request});

  @override
  List<Object?> get props => [id, request];
}

class DeleteGeofenceRequested extends GeofenceEvent {
  final String id;

  const DeleteGeofenceRequested({required this.id});

  @override
  List<Object?> get props => [id];
}

class ToggleGeofenceLockRequested extends GeofenceEvent {
  final String id;
  final bool isLocked;

  const ToggleGeofenceLockRequested({required this.id, required this.isLocked});

  @override
  List<Object?> get props => [id, isLocked];
}

class SearchLocationSuggestionsRequested extends GeofenceEvent {
  final String query;

  const SearchLocationSuggestionsRequested({required this.query});

  @override
  List<Object?> get props => [query];
}

class GetPlaceCoordinatesRequested extends GeofenceEvent {
  final String placeId;

  const GetPlaceCoordinatesRequested({required this.placeId});

  @override
  List<Object?> get props => [placeId];
}

class FetchChildLocationRequested extends GeofenceEvent {
  final String childId;

  const FetchChildLocationRequested({required this.childId});

  @override
  List<Object?> get props => [childId];
}

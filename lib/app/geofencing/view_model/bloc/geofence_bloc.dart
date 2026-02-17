import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../model/geofence_model.dart';
import '../geofence_repository.dart';
import 'geofence_event.dart';
import 'geofence_state.dart';
import 'package:http/http.dart' as http;

class GeofenceBloc extends Bloc<GeofenceEvent, GeofenceState> {
  final GeofenceRepository _repository;

  GeofenceBloc({required GeofenceRepository repository})
    : _repository = repository,
      super(const GeofenceInitial()) {
    on<GeofenceInitializationRequested>(_onGeofenceInitializationRequested);
    on<GetGeofencesRequested>(_onGetGeofencesRequested);
    on<CreateGeofenceRequested>(_onCreateGeofenceRequested);
    on<UpdateGeofenceRequested>(_onUpdateGeofenceRequested);
    on<DeleteGeofenceRequested>(_onDeleteGeofenceRequested);
    on<ToggleGeofenceLockRequested>(_onToggleGeofenceLockRequested);
    on<SearchLocationSuggestionsRequested>(
      _onSearchLocationSuggestionsRequested,
    );
    on<GetPlaceCoordinatesRequested>(_onGetPlaceCoordinatesRequested);
  }

  Future<void> _onGeofenceInitializationRequested(
    GeofenceInitializationRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(const GeofenceLoading());
    try {
      // Initial setup can be done here
      emit(const GeofencesLoaded(geofences: []));
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  Future<void> _onGetGeofencesRequested(
    GetGeofencesRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(const GeofenceLoading());
    try {
      final response = await _repository.getGeofences(event.childId);

      if (response.isSuccess && response.data != null) {
        emit(GeofencesLoaded(geofences: response.data!));
      } else {
        emit(GeofenceError(message: response.message));
      }
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  Future<void> _onCreateGeofenceRequested(
    CreateGeofenceRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(const GeofenceLoading());
    try {
      final response = await _repository.createGeofence(event.request);

      if (response.isSuccess && response.data != null) {
        emit(GeofenceCreated(geofence: response.data!));
      } else {
        emit(GeofenceError(message: response.message));
      }
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  Future<void> _onUpdateGeofenceRequested(
    UpdateGeofenceRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(const GeofenceLoading());
    try {
      final response = await _repository.updateGeofence(
        event.id,
        event.request,
      );

      if (response.isSuccess && response.data != null) {
        emit(GeofenceUpdated(geofence: response.data!));
      } else {
        emit(GeofenceError(message: response.message));
      }
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  Future<void> _onDeleteGeofenceRequested(
    DeleteGeofenceRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(const GeofenceLoading());
    try {
      final response = await _repository.deleteGeofence(event.id);

      if (response.isSuccess) {
        emit(GeofenceDeleted(geofenceId: event.id));
      } else {
        emit(GeofenceError(message: response.message));
      }
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  Future<void> _onToggleGeofenceLockRequested(
    ToggleGeofenceLockRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    try {
      final response = await _repository.toggleGeofenceLock(
        event.id,
        event.isLocked,
      );

      if (response.isSuccess && response.data != null) {
        emit(GeofenceLockToggled(geofence: response.data!));
      } else {
        emit(GeofenceError(message: response.message));
      }
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  Future<void> _onSearchLocationSuggestionsRequested(
    SearchLocationSuggestionsRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    final query = event.query.trim();

    // If empty → clear suggestions
    if (query.isEmpty) {
      emit(const LocationSuggestionsCleared());
      return;
    }

    try {
      const apiKey = "AIzaSyASaOyJsO7dp01jjv625MI9Tw9HwEeTuQg";

      final uri = Uri.https(
        "maps.googleapis.com",
        "/maps/api/place/autocomplete/json",
        {
          "input": query,
          "key": apiKey,
          "components": "country:in", // optional: restrict country
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        emit(const LocationSuggestionsCleared());
        return;
      }

      final data = json.decode(response.body);

      if (data["status"] != "OK") {
        emit(const LocationSuggestionsCleared());
        return;
      }

      final predictions = data["predictions"] as List;

      if (predictions.isEmpty) {
        emit(const LocationSuggestionsCleared());
        return;
      }

      print(
        "Received ${predictions.toString()} predictions from Google Places API",
      );

      final suggestions = predictions.map((prediction) {
        return PlaceAutocompleteResult(
          placeId: prediction["place_id"],
          mainText: prediction["structured_formatting"]["main_text"] ?? "",
          secondaryText:
              prediction["structured_formatting"]["secondary_text"] ?? "",
          description: prediction["description"] ?? "",
        );
      }).toList();

      emit(LocationSuggestionsLoaded(suggestions: suggestions));
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  Future<void> _onGetPlaceCoordinatesRequested(
    GetPlaceCoordinatesRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    try {
      final coordinates = await getPlaceLatLng(event.placeId);
      if (coordinates != null) {
        emit(PlaceCoordinatesLoaded(coordinates: coordinates));
      } else {
        emit(
          const GeofenceError(message: "Could not fetch place coordinates"),
        );
      }
    } catch (e) {
      emit(GeofenceError(message: e.toString()));
    }
  }

  Future<LatLng?> getPlaceLatLng(String placeId) async {
    const apiKey = "AIzaSyASaOyJsO7dp01jjv625MI9Tw9HwEeTuQg";

    final uri = Uri.https(
      "maps.googleapis.com",
      "/maps/api/place/details/json",
      {
        "place_id": placeId,
        "key": apiKey,
        "fields": "geometry", // IMPORTANT: only request what you need
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);

      if (data["status"] != "OK") return null;

      final location = data["result"]["geometry"]["location"];

      return LatLng(location["lat"], location["lng"]);
    } catch (e) {
      return null;
    }
  }
}

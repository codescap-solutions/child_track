import 'dart:convert';
import 'package:child_track/app/addplace/model/saved_place_model.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/utils/app_logger.dart';

class SavedPlacesService {
  static const String _savedPlacesKey = 'saved_places';

  // Save a place
  Future<bool> savePlace(SavedPlace place) async {
    try {
      final places = await getSavedPlaces();
      places.add(place);
      final jsonList = places.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await SharedPrefsService.prefs.setString(_savedPlacesKey, jsonString);
      AppLogger.info('Place saved: ${place.name}');
      return true;
    } catch (e) {
      AppLogger.error('Error saving place: $e');
      return false;
    }
  }

  // Get all saved places
  Future<List<SavedPlace>> getSavedPlaces() async {
    try {
      final jsonString = SharedPrefsService.prefs.getString(_savedPlacesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => SavedPlace.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.error('Error getting saved places: $e');
      return [];
    }
  }

  // Delete a place
  Future<bool> deletePlace(String placeId) async {
    try {
      final places = await getSavedPlaces();
      places.removeWhere((place) => place.id == placeId);
      final jsonList = places.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await SharedPrefsService.prefs.setString(_savedPlacesKey, jsonString);
      AppLogger.info('Place deleted: $placeId');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting place: $e');
      return false;
    }
  }

  // Clear all saved places
  Future<bool> clearAllPlaces() async {
    try {
      await SharedPrefsService.prefs.remove(_savedPlacesKey);
      AppLogger.info('All places cleared');
      return true;
    } catch (e) {
      AppLogger.error('Error clearing places: $e');
      return false;
    }
  }
}


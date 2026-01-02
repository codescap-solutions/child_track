import 'package:child_track/app/addplace/model/saved_place_model.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/api_endpoints.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/utils/app_logger.dart';

class SavedPlacesService {
  final DioClient _dioClient = injector<DioClient>();

  // Save a place
  Future<bool> savePlace(SavedPlace place) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.places,
        data: place.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.info('Place saved: ${place.name}');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error saving place: $e');
      return false;
    }
  }

  // Get all saved places
  Future<List<SavedPlace>> getSavedPlaces() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.places);

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => SavedPlace.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('Error getting saved places: $e');
      return [];
    }
  }

  // Delete a place
  Future<bool> deletePlace(String placeId) async {
    try {
      final response = await _dioClient.delete(
        '${ApiEndpoints.places}/$placeId',
      );

      if (response.statusCode == 200) {
        AppLogger.info('Place deleted: $placeId');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error deleting place: $e');
      return false;
    }
  }
}

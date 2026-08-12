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
  Future<List<SavedPlace>> getSavedPlaces({String? childId}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (childId != null) {
        queryParams['child_id'] = childId;
      }

      final response = await _dioClient.get(
        ApiEndpoints.places,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data']['places'] ?? [];
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

  // Update a place
  Future<bool> updatePlace(String placeId, SavedPlace place) async {
    try {
      final response = await _dioClient.put(
        ApiEndpoints.placeDetail(placeId),
        data: place.toJson(),
      );

      if (response.statusCode == 200) {
        AppLogger.info('Place updated: ${place.name}');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error updating place: $e');
      return false;
    }
  }

  // Assign a child to a place
  Future<bool> assignChildToPlace(String placeId, String childId) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.assignChildToPlace(placeId),
        data: {'child_id': childId},
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Error assigning child to place: $e');
      return false;
    }
  }

  // Unassign a child from a place
  Future<bool> unassignChildFromPlace(String placeId, String childId) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.unassignChildFromPlace(placeId),
        data: {'child_id': childId},
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Error unassigning child from place: $e');
      return false;
    }
  }

  // Assign all children to a place
  Future<bool> assignAllChildrenToPlace(String placeId) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.assignAllChildrenToPlace(placeId),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Error assigning all children to place: $e');
      return false;
    }
  }
}

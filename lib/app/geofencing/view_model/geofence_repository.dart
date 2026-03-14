import 'dart:developer';

import '../../../core/services/dio_client.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../../../core/services/api_endpoints.dart';
import '../../../core/services/base_service.dart';
import '../model/geofence_model.dart';

class GeofenceRepository extends BaseService {
  GeofenceRepository({
    required DioClient dioClient,
    required SharedPrefsService sharedPrefsService,
  }) : super(dioClient);

  // Create Geofence
  Future<BaseResponse<Geofence>> createGeofence(
    CreateGeofenceRequest request,
  ) async {
    try {
      log('Creating geofence with data: ${request.toJson()}');
      final response = await post(ApiEndpoints.places, data: request.toJson());

      if (response.isSuccess && response.data != null) {
        final geofence = Geofence.fromJson(response.data);
        return BaseResponse.success(data: geofence, message: response.message);
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Get Geofences List
  Future<BaseResponse<List<Geofence>>> getGeofences(
    String childId, {
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    try {
      log('Fetching geofences for child ID: $childId, date: $date');
      final queryParams = <String, dynamic>{'child_id': childId};

      // Prefer explicit range when both startDate and endDate are provided
      if (startDate != null && endDate != null) {
        queryParams['startDate'] = startDate;
        queryParams['endDate'] = endDate;
      } else if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final response = await get(
        ApiEndpoints.places,
        queryParameters: queryParams,
      );
      log('Response received: ${response.data}');
      if (response.isSuccess && response.data != null) {
        final List<dynamic> dataList = response.data is List
            ? response.data
            : (response.data as Map)['places'] ??
                  (response.data as Map)['data']?['places'] ??
                  []; // Map from Places array

        final geofences = (dataList).map((item) {
          final itemData = item is Map<String, dynamic>
              ? item
              : {} as Map<String, dynamic>;
          return Geofence.fromJson(itemData);
        }).toList();

        return BaseResponse.success(data: geofences, message: response.message);
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Update Geofence
  Future<BaseResponse<Geofence>> updateGeofence(
    String id,
    UpdateGeofenceRequest request,
  ) async {
    try {
      final response = await put(
        ApiEndpoints.placeDetail(id),
        data: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final dataMap = response.data is Map
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final placeData = dataMap.containsKey('place')
            ? dataMap['place']
            : (dataMap.containsKey('data') ? dataMap['data'] : dataMap);

        final geofence = Geofence.fromJson(placeData as Map<String, dynamic>);
        return BaseResponse.success(data: geofence, message: response.message);
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Lock/Unlock Geofence -> Toggle Notification
  Future<BaseResponse<Geofence>> toggleGeofenceLock(
    String id,
    bool isLocked,
  ) async {
    try {
      final response = await patch(
        ApiEndpoints.togglePlaceNotification(id),
        data: {'notifyOnArrival': isLocked},
      );

      if (response.isSuccess && response.data != null) {
        log('💡 [toggleGeofenceLock] Response SUCCESS: ${response.data}');
        final dataMap = response.data is Map
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        final placeData = dataMap.containsKey('place')
            ? dataMap['place']
            : (dataMap.containsKey('data') ? dataMap['data'] : dataMap);

        final geofence = Geofence.fromJson(placeData as Map<String, dynamic>);
        log(
          '💡 [toggleGeofenceLock] Parsed Geofence: isLocked=${geofence.isLocked}',
        );
        return BaseResponse.success(data: geofence, message: response.message);
      }

      log('💡 [toggleGeofenceLock] Response ERROR: ${response.message}');
      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Delete Geofence
  Future<BaseResponse<void>> deleteGeofence(String id) async {
    try {
      final response = await delete(ApiEndpoints.placeDetail(id));

      if (response.isSuccess) {
        return BaseResponse.success(data: null, message: response.message);
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }
}

import '../../../core/services/dio_client.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../../../core/services/api_endpoints.dart';
import '../../../core/services/base_service.dart';
import '../model/geofence_model.dart';

class GeofenceRepository extends BaseService {
  final SharedPrefsService _sharedPrefsService;

  GeofenceRepository({
    required DioClient dioClient,
    required SharedPrefsService sharedPrefsService,
  })  : _sharedPrefsService = sharedPrefsService,
        super(dioClient);

  // Create Geofence
  Future<BaseResponse<Geofence>> createGeofence(
      CreateGeofenceRequest request) async {
    try {
      final response = await post(
        ApiEndpoints.geofences,
        data: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final geofence = Geofence.fromJson(response.data);
        return BaseResponse.success(
          data: geofence,
          message: response.message,
        );
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Get Geofences List
  Future<BaseResponse<List<Geofence>>> getGeofences(String childId) async {
    try {
      final response = await get(
        ApiEndpoints.geofences,
        queryParameters: {'child_id': childId},
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> dataList = response.data is List
            ? response.data
            : (response.data as Map)['data'] ?? [];

        final geofences = (dataList).map((item) {
          final itemData = item is Map<String, dynamic> ? item : {} as Map<String,dynamic>;
          return Geofence.fromJson(itemData);
        }).toList();

        return BaseResponse.success(
          data: geofences,
          message: response.message,
        );
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
        ApiEndpoints.geofenceDetail(id),
        data: request.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        final geofence = Geofence.fromJson(response.data);
        return BaseResponse.success(
          data: geofence,
          message: response.message,
        );
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Lock/Unlock Geofence
  Future<BaseResponse<Geofence>> toggleGeofenceLock(
    String id,
    bool isLocked,
  ) async {
    try {
      final response = await patch(
        ApiEndpoints.geofenceLock(id),
        data: {'is_locked': isLocked},
      );

      if (response.isSuccess && response.data != null) {
        final geofence = Geofence.fromJson(response.data);
        return BaseResponse.success(
          data: geofence,
          message: response.message,
        );
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // Delete Geofence
  Future<BaseResponse<void>> deleteGeofence(String id) async {
    try {
      final response = await delete(
        ApiEndpoints.geofenceDetail(id),
      );

      if (response.isSuccess) {
        return BaseResponse.success(
          data: null,
          message: response.message,
        );
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }
}

import 'package:child_track/core/services/api_endpoints.dart';
import 'package:child_track/core/services/base_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';

class ChildRepo extends BaseService {
  final SharedPrefsService _sharedPrefsService;
  
  ChildRepo({
    required DioClient dioClient,
    SharedPrefsService? sharedPrefsService,
  }) : _sharedPrefsService = sharedPrefsService ?? SharedPrefsService(),
       super(dioClient);

  Future<BaseResponse> createChild({
    required String name,
    required int age,
  }) async {
    final parentId = _sharedPrefsService.getString('parent_id') ?? 
                     _sharedPrefsService.getUserId();
    
    if (parentId == null) {
      return BaseResponse.error(
        message: 'Parent ID not found. Please login again.',
      );
    }

    final response = await post(
      ApiEndpoints.createChild,
      data: {
        'name': name,
        'age': age,
        'parent_id': parentId,
      },
    );
    return response;
  }

  Future<BaseResponse> postChildData(Map<String, dynamic> data) async {
    final response = await post(ApiEndpoints.postDeviceInfo, data: data);
    return response;
  }

  Future<BaseResponse> postScreenTime(Map<String, dynamic> data) async {
    final response = await post(ApiEndpoints.postScreenTime, data: data);
    return response;
  }

  Future<BaseResponse> postChildLocation(Map<String, dynamic> data) async {
    final response = await post(ApiEndpoints.postLocation, data: data);
    return response;
  }

  Future<BaseResponse> postTripEvent(Map<String, dynamic> data) async {
    final response = await post(ApiEndpoints.postTripEvent, data: data);
    return response;
  }
}

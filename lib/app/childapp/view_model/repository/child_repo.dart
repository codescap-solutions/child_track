import 'package:child_track/core/models/base_response.dart';
import 'package:child_track/core/services/api_endpoints.dart';
import 'package:child_track/core/services/base_service.dart';
import 'package:child_track/core/services/dio_client.dart';

class ChildRepo extends BaseService {
  ChildRepo({required DioClient dioClient}) : super(dioClient);

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

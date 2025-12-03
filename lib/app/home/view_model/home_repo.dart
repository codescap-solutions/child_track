import 'dart:convert';
import 'package:child_track/app/home/model/home_model.dart';
import 'package:child_track/core/services/api_endpoints.dart';
import 'package:child_track/core/services/base_service.dart';
import 'package:child_track/core/services/dio_client.dart';

class HomeRepository extends BaseService {
  HomeRepository({required DioClient dioClient}) : super(dioClient);

  Future<BaseResponse<HomeResponse>> getHomeData({String? childId}) async {
    final response = await get<Map<String, dynamic>>(
      ApiEndpoints.getHome,
      queryParameters: childId != null ? {'child_id': childId} : null,
    );
    
    if (response.isSuccess && response.data != null) {
      try {
        final homeData = HomeResponse.fromJson(response.data!);
        return BaseResponse.success(data: homeData, message: response.message);
      } catch (e) {
        return BaseResponse.error(
          message: 'Failed to parse home data: ${e.toString()}',
        );
      }
    }
    
    return BaseResponse.error(
      message: response.message,
      statusCode: response.statusCode,
    );
  }

  Future<BaseResponse> getCurrentLocationDetails() async {
    await Future.delayed(const Duration(seconds: 1));
    return BaseResponse(
      isSuccess: true,
      message: "Static current location details",
      data: jsonEncode({
        "lat": 11.2488,
        "lng": 75.7839,
        "address": "Cubbon Road, Bengaluru",
        "place_name": "School",
        "since": "9:30am",
        "duration_minutes": 120,
      }),
    );
  }

  Future<BaseResponse> getTrips({
    String? childId,
    int? page,
    int? pageSize,
  }) async {
    final queryParams = <String, dynamic>{};
    if (childId != null) queryParams['child_id'] = childId;
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['page_size'] = pageSize;

    final response = await get(
      ApiEndpoints.getTrips,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return response;
  }

  Future<BaseResponse> getTripDetail(String tripId) async {
    final response = await get(ApiEndpoints.getTripDetail(tripId));
    return response;
  }
}

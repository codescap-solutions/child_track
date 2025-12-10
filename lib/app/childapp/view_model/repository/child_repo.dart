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

  Future<BaseResponse> childLogin({required String childCode}) async {
    try {
      final response = await post(
        ApiEndpoints.childLogin,
        data: {'child_code': childCode},
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final token = data['token'] as String?;
        final childId = data['child_id'] as String? ?? data['_id'] as String?;

        if (token != null) {
          await _sharedPrefsService.setAuthToken(token);
        }
        if (childId != null) {
          await _sharedPrefsService.setString('child_id', childId);
          await _sharedPrefsService.setString('child_code', childCode);
        }
      }

      return response;
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  Future<BaseResponse> createChild({
    required String name,
    required int age,
  }) async {
    final response = await post(
      ApiEndpoints.createChild,
      data: {
        'name': name,
        'age': age,
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

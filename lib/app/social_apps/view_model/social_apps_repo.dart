import 'package:child_track/app/social_apps/model/app_usage_model.dart';
import 'package:child_track/core/services/api_endpoints.dart';
import 'package:child_track/core/services/base_service.dart';
import 'package:child_track/core/services/dio_client.dart';

class SocialAppsRepository extends BaseService {
  SocialAppsRepository({required DioClient dioClient}) : super(dioClient);

  Future<BaseResponse<AppUsageResponse>> getAppUsage({
    required String childId,
    required String date,
  }) async {
    final response = await get<Map<String, dynamic>>(
      ApiEndpoints.getAppUsage,
      queryParameters: {
        'userId': childId, // user provided 'userId' in query param example
        'date': date,
      },
    );

    if (response.isSuccess && response.data != null) {
      try {
        final appUsageData = AppUsageResponse.fromJson(response.data!);
        return BaseResponse.success(
          data: appUsageData,
          message: response.message,
        );
      } catch (e) {
        return BaseResponse.error(
          message: 'Failed to parse app usage data: ${e.toString()}',
        );
      }
    }

    return BaseResponse.error(
      message: response.message,
      statusCode: response.statusCode,
    );
  }
}

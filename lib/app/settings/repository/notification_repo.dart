import '../../../core/services/api_endpoints.dart';
import '../../../core/services/base_service.dart';
import '../../../core/services/dio_client.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../models/notification_settings_model.dart';

class NotificationRepository extends BaseService {
  NotificationRepository({required DioClient dioClient}) : super(dioClient);

  Future<BaseResponse<NotificationSettingsModel>> fetchSettings() async {
    try {
      final response = await get(ApiEndpoints.notificationSettings);

      if (response.isSuccess && response.data != null) {
        final model = NotificationSettingsModel.fromJson(response.data);
        return BaseResponse.success(data: model, message: response.message);
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  Future<BaseResponse<void>> updateAll(NotificationSettingsModel model) async {
    try {
      final response = await put(
        ApiEndpoints.notificationSettings,
        data: model.toJson(),
      );

      if (response.isSuccess) {
        final sharedPrefsService = SharedPrefsService();
        sharedPrefsService.getBool(
          'notification_settings',
          defaultValue: model.masterEnabled ?? false,
        );
        return BaseResponse.success(data: null, message: response.message);
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  Future<BaseResponse<void>> updateSingle(
    String category,
    String key,
    bool value,
  ) async {
    try {
      final response = await patch(
        ApiEndpoints.notificationSettings,
        data: {
          category: {key: value},
        },
      );

      if (response.isSuccess) {
        return BaseResponse.success(data: null, message: response.message);
      }

      return BaseResponse.error(message: response.message);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }
}

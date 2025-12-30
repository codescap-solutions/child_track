import 'dart:developer';

import 'package:child_track/core/services/api_endpoints.dart';
import 'package:child_track/core/services/base_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
import 'package:child_track/core/services/socket_service.dart';
import 'package:child_track/core/utils/app_logger.dart';

class ChildRepo extends BaseService {
  final SharedPrefsService _sharedPrefsService;
  // final SocketService _socketService = SocketService();

  ChildRepo({
    required DioClient dioClient,
    SharedPrefsService? sharedPrefsService,
  }) : _sharedPrefsService = sharedPrefsService ?? SharedPrefsService(),
       super(dioClient);

  // void initializeSocket(String childId) {
  //   _socketService.initSocket();
  //   _socketService.joinRoom(childId);
  // }

  Future<BaseResponse> childLogin({required String childCode}) async {
    try {
      final response = await post(
        ApiEndpoints.childLogin,
        data: {'child_code': childCode},
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final token = data['token'] as String?;
        final childId =
            data['child']?['child_id'] as String? ?? data['_id'] as String?;

        if (token != null) {
          await _sharedPrefsService.setAuthToken(token);
          AppLogger.info('Child login: Auth token saved');
        }
        if (childId != null) {
          await _sharedPrefsService.setString('child_id', childId);
          log('child_id saved: $childId');
          await _sharedPrefsService.setString('child_code', childCode);
          AppLogger.info('Child login: Child ID saved: $childId');

          // Verify it was saved correctly
          final savedChildId = _sharedPrefsService.getString('child_id');
          AppLogger.info('Child login: Verified saved child_id: $savedChildId');

          // Initialize Socket
          // _socketService.initSocket();
          // _socketService.joinRoom(childId);
        } else {
          AppLogger.warning('Child login: Child ID not found in response');
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
      data: {'name': name, 'age': age},
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
    // if (_socketService.isConnected) {
    //   _socketService.sendLocation(data);
    //   return BaseResponse.success(
    //     data: null,
    //     message: "Location sent via Socket",
    //   );
    // }
    final response = await post(ApiEndpoints.postLocation, data: data);
    return response;
  }

  Future<BaseResponse> postTripEvent(Map<String, dynamic> data) async {
    // For critical trip events, we might want to send via both or prefer REST for reliability,
    // but the requirement is to use Socket. Let's use Socket if connected, else REST.
    // if (_socketService.isConnected) {
    //   // Determine event name based on data or context.
    //   // Assuming 'status' field exists or we infer it.
    //   // The requirement says events: trip_started, trip_updated, trip_ended.
    //   // We'll pass the whole data payload to a generic trip event or specific ones.
    //   // For now, let's assume 'trip_update' as a generic container or check payload.
    //   String eventName = 'trip_update';
    //   if (data['status'] == 'started') eventName = 'trip_started';
    //   if (data['status'] == 'ended') eventName = 'trip_ended';

    //   _socketService.emitTripEvent(eventName, data);
    //   return BaseResponse.success(
    //     data: null,
    //     message: "Trip event sent via Socket",
    //   );
    // }
    final response = await post(ApiEndpoints.postTripEvent, data: data);
    return response;
  }
}

import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';

import 'package:child_track/core/services/api_endpoints.dart';
import 'package:child_track/core/services/base_service.dart';
import 'package:child_track/core/services/dio_client.dart';
import 'package:child_track/core/services/shared_prefs_service.dart';
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

          final name = data['child']?['name'] as String?;
          if (name != null) {
            await _sharedPrefsService.setString('child_name', name);
          }

          final parentPhone = data['child']?['parent_phone']?.toString();
          if (parentPhone != null) {
            await _sharedPrefsService.setString('parent_phone', parentPhone);
          }

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

  Future<BaseResponse> getAvailableIcons() async {
    AppLogger.info('ChildRepo: Fetching available icons...');
    final response = await get(ApiEndpoints.getAvailableIcons);
    if (response.isSuccess) {
      AppLogger.info('ChildRepo: Available icons fetched: ${response.data}');
    } else {
      AppLogger.error('ChildRepo: Failed to fetch icons: ${response.message}');
    }
    return response;
  }

  Future<BaseResponse> uploadIcons(Map<String, String> iconsToUpload) async {
    AppLogger.info('ChildRepo: Uploading ${iconsToUpload.length} icons...');
    final formData = FormData();

    iconsToUpload.forEach((package, iconBase64) {
      if (iconBase64.isNotEmpty) {
        try {
          final bytes = base64Decode(iconBase64);
          formData.files.add(
            MapEntry(
              package,
              MultipartFile.fromBytes(bytes, filename: '$package.png'),
            ),
          );
        } catch (e) {
          AppLogger.error('Error decoding icon for $package: $e');
        }
      }
    });

    final response = await post(ApiEndpoints.uploadIcons, data: formData);
    if (response.isSuccess) {
      AppLogger.info(
        'ChildRepo: Icons uploaded successfully: ${response.message}',
      );
    } else {
      AppLogger.error('ChildRepo: Failed to upload icons: ${response.message}');
    }
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

  Future<BaseResponse> postTripLocation({
    required String childId,
    required Map<String, dynamic> data,
  }) async {
    final response = await post(
      ApiEndpoints.postTripLocation(childId),
      data: data,
    );
    return response;
  }
}

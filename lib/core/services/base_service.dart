import 'package:child_track/core/models/base_response.dart';

import 'dio_client.dart';


abstract class BaseService {
  final DioClient _dioClient;

  BaseService(this._dioClient);

  // GET Request
  Future<BaseResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dioClient.get(
        path,
        queryParameters: queryParameters,
      );

      return BaseResponse.fromJson(response.data, fromJson);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // POST Request
  Future<BaseResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dioClient.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return BaseResponse.fromJson(response.data, fromJson);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // PUT Request
  Future<BaseResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dioClient.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return BaseResponse.fromJson(response.data, fromJson);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }

  // DELETE Request
  Future<BaseResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dioClient.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return BaseResponse.fromJson(response.data, fromJson);
    } catch (e) {
      return BaseResponse.error(message: e.toString());
    }
  }
}

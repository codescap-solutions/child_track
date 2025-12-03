import 'dio_client.dart';

class BaseResponse<T> {
  final bool isSuccess;
  final String message;
  final T? data;
  final int? statusCode;

  BaseResponse({
    required this.isSuccess,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory BaseResponse.fromJson(Map<String, dynamic> json) {
    return BaseResponse<T>(
      isSuccess: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      statusCode: json['status_code'],
    );
  }

  factory BaseResponse.success({
    required T data,
    String message = 'Success',
    int? statusCode,
  }) {
    return BaseResponse<T>(
      isSuccess: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  factory BaseResponse.error({required String message, int? statusCode}) {
    return BaseResponse<T>(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

abstract class BaseService {
  final DioClient _dioClient;

  BaseService(this._dioClient);

  // Extract error message from exception, removing "Exception:" prefix if present
  String _extractErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unknown error occurred';
    }

    String errorMessage = error.toString();

    // Remove "Exception: " prefix if present
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring('Exception: '.length);
    }

    return errorMessage;
  }

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

      return BaseResponse.fromJson(response.data);
    } catch (e) {
      return BaseResponse.error(message: _extractErrorMessage(e));
    }
  }

  // POST Request
  Future<BaseResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return BaseResponse.fromJson(response.data);
    } catch (e) {
      return BaseResponse.error(message: _extractErrorMessage(e));
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

      return BaseResponse.fromJson(response.data);
    } catch (e) {
      return BaseResponse.error(message: _extractErrorMessage(e));
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

      return BaseResponse.fromJson(response.data);
    } catch (e) {
      return BaseResponse.error(message: _extractErrorMessage(e));
    }
  }
}

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../utils/app_logger.dart';
import 'shared_prefs_service.dart';

class DioClient {
  late Dio _dio;
  final SharedPrefsService _sharedPrefsService =
      GetIt.instance<SharedPrefsService>();

  DioClient() {
    _dio = Dio();
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.info('🚀 Request: ${options.method} ${options.uri}');
          AppLogger.debug('Request Data: ${options.data}');
          AppLogger.debug('Request Headers: ${options.headers}');

          // Add auth token if available
          final token = _sharedPrefsService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info(
            '✅ Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          AppLogger.debug('Response Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.error('❌ Error: ${error.message}');
          AppLogger.debug('Error Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );

    // Logging Interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => AppLogger.debug(obj.toString()),
      ),
    );
  }

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error Handler
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Request timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            error.response?.data?['message'] ?? 'Server error occurred';

        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception('Unauthorized: Please login again');
          case 403:
            return Exception('Forbidden: Access denied');
          case 404:
            return Exception('Not found: $message');
          case 500:
            return Exception('Internal server error: $message');
          default:
            return Exception('Server error: $message');
        }

      case DioExceptionType.cancel:
        return Exception('Request was cancelled');

      case DioExceptionType.connectionError:
        return Exception(
          'Connection error. Please check your internet connection.',
        );

      case DioExceptionType.badCertificate:
        return Exception('Certificate error. Please try again.');

      case DioExceptionType.unknown:
        return Exception('An unknown error occurred. Please try again.');
    }
  }

  // Get Dio instance for custom requests
  Dio get dio => _dio;
}

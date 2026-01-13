import 'dart:convert';

import 'package:child_track/core/models/base_response.dart';
import 'package:dio/dio.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:child_track/core/services/api_endpoints.dart';
import '../utils/app_logger.dart';
import 'shared_prefs_service.dart';
import 'package:child_track/core/services/connectivity/bloc/connectivity_bloc.dart';

// Helper class to store pending requests during token refresh
class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.requestOptions, required this.handler});
}

class DioClient {
  late Dio _dio;
  final SharedPrefsService _sharedPrefsService = injector<SharedPrefsService>();
  final ConnectivityBloc _connectivityBloc;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  DioClient({required ConnectivityBloc connectivityBloc})
    : _connectivityBloc = connectivityBloc {
    _dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.info('🚀 Request url: ${options.method} ${options.uri}');
          try {
            if (options.data is FormData) {
              AppLogger.debug('Request Data: [FormData]');
            } else {
              AppLogger.debug('Request Data: ${jsonEncode(options.data)}');
            }
            AppLogger.debug('Request Headers: ${jsonEncode(options.headers)}');
          } catch (e) {
            AppLogger.debug('Request Data (raw): ${options.data}');
          }

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
        onError: (error, handler) async {
          AppLogger.error('❌ Error: ${error.message}');
          AppLogger.debug('Error Response: ${error.response?.data}');

          // Handle 401 Unauthorized - Try to refresh token
          if (error.response?.statusCode == 401) {
            final requestOptions = error.requestOptions;

            // Don't retry refresh token endpoint itself
            final path = requestOptions.path.toLowerCase();
            final uri = requestOptions.uri.toString().toLowerCase();
            if (path.contains('refresh-token') ||
                uri.contains('refresh-token')) {
              AppLogger.error(
                'Refresh token failed, user needs to login again',
              );
              handler.next(error);
              return;
            }

            // If already refreshing, queue this request
            if (_isRefreshing) {
              AppLogger.info('Token refresh in progress, queuing request');
              _pendingRequests.add(
                _PendingRequest(
                  requestOptions: requestOptions,
                  handler: handler,
                ),
              );
              return;
            }

            _isRefreshing = true;
            AppLogger.info('Attempting to refresh token...');

            try {
              final refreshResponse = BaseResponse.success(
                data: {'token': 'new_token'},
              );

              if (refreshResponse.isSuccess) {
                AppLogger.info(
                  'Token refreshed successfully, retrying request',
                );

                // Update token in request
                final newToken = _sharedPrefsService.getAuthToken();
                if (newToken != null && newToken.isNotEmpty) {
                  requestOptions.headers['Authorization'] = 'Bearer $newToken';
                }

                // Retry the original request
                try {
                  final response = await _dio.fetch(requestOptions);
                  handler.resolve(response);

                  // Process pending requests
                  await _processPendingRequests();
                } catch (e) {
                  // If retry fails, pass the new error
                  final dioError = e is DioException
                      ? e
                      : DioException(requestOptions: requestOptions, error: e);
                  handler.reject(dioError);
                  await _processPendingRequests();
                }
              } else {
                AppLogger.error(
                  'Token refresh failed: ${refreshResponse.message}',
                );
                handler.next(error);
                await _rejectPendingRequests(error);
              }
            } catch (e) {
              AppLogger.error('Error during token refresh: $e');
              handler.next(error);
              await _rejectPendingRequests(error);
            } finally {
              _isRefreshing = false;
            }
          } else {
            handler.next(error);
          }
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
        // logPrint: (obj) => AppLogger.debug(obj.toString()),
      ),
    );
  }

  // Process pending requests after token refresh
  Future<void> _processPendingRequests() async {
    final pending = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    final newToken = _sharedPrefsService.getAuthToken();

    for (final pendingRequest in pending) {
      try {
        // Update token in request
        if (newToken != null && newToken.isNotEmpty) {
          pendingRequest.requestOptions.headers['Authorization'] =
              'Bearer $newToken';
        }

        // Retry the request
        final response = await _dio.fetch(pendingRequest.requestOptions);
        pendingRequest.handler.resolve(response);
      } catch (e) {
        final dioError = e is DioException
            ? e
            : DioException(
                requestOptions: pendingRequest.requestOptions,
                error: e,
              );
        pendingRequest.handler.reject(dioError);
      }
    }
  }

  // Reject all pending requests when token refresh fails
  Future<void> _rejectPendingRequests(DioException error) async {
    final pending = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final pendingRequest in pending) {
      // Create a new error with the pending request's options
      final dioError = DioException(
        requestOptions: pendingRequest.requestOptions,
        response: error.response,
        type: error.type,
        error: error.error,
      );
      pendingRequest.handler.reject(dioError);
    }
  }

  // Check connectivity before making request
  void _checkConnectivity() {
    final state = _connectivityBloc.state;
    if (state is ConnectivityOffline) {
      throw Exception('Internet not available. Please check your connection.');
    }
  }

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    _checkConnectivity();
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
    _checkConnectivity();
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
    _checkConnectivity();
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
    _checkConnectivity();
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

  // Extract error message from response data safely
  String _extractErrorMessage(dynamic data) {
    if (data == null) {
      return 'Server error occurred';
    }

    // If data is a String, return it directly
    if (data is String) {
      return data.isNotEmpty ? data : 'Server error occurred';
    }

    // If data is a Map, try to extract message
    if (data is Map) {
      // Try 'message' key first
      if (data.containsKey('message') && data['message'] != null) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }

      // Try 'error' key as fallback
      if (data.containsKey('error') && data['error'] != null) {
        final error = data['error'];
        if (error is String && error.isNotEmpty) {
          return error;
        }
        // If error is a Map, try to get message from it
        if (error is Map && error.containsKey('message')) {
          final message = error['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
        }
      }

      // Try 'detail' key as another fallback
      if (data.containsKey('detail') && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    }

    return 'Server error occurred';
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
        final message = _extractErrorMessage(error.response?.data);

        switch (statusCode) {
          case 400:
            AppLogger.error('Bad request:', message, StackTrace.current);
            return Exception(
              message.isNotEmpty
                  ? message
                  : 'Bad request: Please check your request',
            );
          case 401:
            AppLogger.error('Unauthorized:', message, StackTrace.current);
            return Exception('Unauthorized: Please login again to continue');
          case 403:
            AppLogger.error('Access denied:', message, StackTrace.current);
            return Exception(
              'Access denied: You are not authorized to access this resource',
            );
          case 404:
            AppLogger.error('Not found:', message, StackTrace.current);
            return Exception('Not found: The requested resource was not found');
          case 500:
            AppLogger.error(
              'Internal server error:',
              message,
              StackTrace.current,
            );
            return Exception('Internal server error: Please try again later');
          default:
            AppLogger.error('Server error:', message, StackTrace.current);
            return Exception('Server error: Please try again later');
        }

      case DioExceptionType.cancel:
        AppLogger.error(
          'Request cancelled:',
          error.message,
          StackTrace.current,
        );
        return Exception('Request was cancelled');

      case DioExceptionType.connectionError:
        AppLogger.error('Connection error:', error.message, StackTrace.current);
        return Exception(
          'Connection error. Please check your internet connection.',
        );

      case DioExceptionType.badCertificate:
        AppLogger.error(
          'Certificate error:',
          error.message,
          StackTrace.current,
        );
        return Exception('Certificate error. Please try again.');

      case DioExceptionType.unknown:
        AppLogger.error('Unknown error:', error.message, StackTrace.current);
        return Exception('An unknown error occurred. Please try again.');
    }
  }

  // Get Dio instance for custom requests
  Dio get dio => _dio;
}

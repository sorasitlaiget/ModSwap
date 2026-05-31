import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import '../utils/logger.dart';

/// Dio HTTP client - similar to Axios on the web.
/// Handles automatic token attachment, logging, and error normalization.
class DioClient {
  final AuthService _authService;
  late final Dio _dio;

  Dio get dio => _dio;

  DioClient(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth Interceptor: attach Firebase ID Token to every request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Normalize errors: extract message from Backend's response format
          // Backend sends: { success: false, error: { code, message } }
          if (error.response?.data is Map) {
            final data = error.response!.data as Map;
            final errorObj = data['error'];
            if (errorObj is Map && errorObj['message'] is String) {
              error = error.copyWith(message: errorObj['message'] as String);
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Logging Interceptor (only in debug mode)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => AppLogger.d('[Dio] $obj'),
        ),
      );
    }
  }

  Future<T> get<T>(String path) async {
    final response = await _dio.get(path);
    return response.data['data'] as T;
  }

  Future<T> post<T>(String path, {Map<String, dynamic>? body}) async {
    final response = await _dio.post(path, data: body);
    return response.data['data'] as T;
  }

  Future<T> patch<T>(String path, {Map<String, dynamic>? body}) async {
    final response = await _dio.patch(path, data: body);
    return response.data['data'] as T;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}

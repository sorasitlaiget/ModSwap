import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../utils/logger.dart';

class DioClient {
  late final Dio dio;

  DioClient(FirebaseAuth auth) {
    dio = Dio(
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

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await auth.currentUser?.getIdToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onError: (error, handler) {
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

    if (kDebugMode) {
      dio.interceptors.add(
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
    final r = await dio.get(path);
    return r.data['data'] as T;
  }

  Future<T> post<T>(String path, {Map<String, dynamic>? body}) async {
    final r = await dio.post(path, data: body);
    return r.data['data'] as T;
  }

  Future<T> patch<T>(String path, {Map<String, dynamic>? body}) async {
    final r = await dio.patch(path, data: body);
    return r.data['data'] as T;
  }

  Future<void> delete(String path) async {
    await dio.delete(path);
  }
}

import 'package:dio/dio.dart';
import '../models/user_profile.dart';
import 'dio_client.dart';

/// API Service - calls Backend Cloud Functions
class ApiService {
  final DioClient _client;

  ApiService(this._client);

  /// GET /auth/me - Get current user's profile
  Future<UserProfile> getMyProfile() async {
    try {
      final data = await _client.get<Map<String, dynamic>>('/auth/me');
      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw _toUserMessage(e);
    }
  }

  /// POST /auth/complete-profile - Complete profile after registration
  Future<UserProfile> completeProfile({
    required String displayName,
    required String studentId,
    required String faculty,
    required String lineId,
  }) async {
    try {
      final data = await _client.post<Map<String, dynamic>>(
        '/auth/complete-profile',
        body: {
          'displayName': displayName,
          'studentId': studentId,
          'faculty': faculty,
          'lineId': lineId,
        },
      );
      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw _toUserMessage(e);
    }
  }

  /// PATCH /auth/profile - Update existing profile
  Future<UserProfile> updateProfile({
    String? displayName,
    String? studentId,
    String? faculty,
    String? lineId,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (studentId != null) body['studentId'] = studentId;
    if (faculty != null) body['faculty'] = faculty;
    if (lineId != null) body['lineId'] = lineId;

    try {
      final data = await _client.patch<Map<String, dynamic>>(
        '/auth/profile',
        body: body,
      );
      return UserProfile.fromJson(data);
    } on DioException catch (e) {
      throw _toUserMessage(e);
    }
  }

  Exception _toUserMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please try again.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception('Cannot connect to server. Check your internet.');
    }
    final message = e.message ?? 'An error occurred';
    return Exception(message);
  }
}

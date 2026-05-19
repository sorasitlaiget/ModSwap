import 'package:dio/dio.dart';
import '../models/listing.dart';
import 'auth_service.dart';
import 'dio_client.dart';

/// Service for Listings API
class ListingsService {
  final DioClient _dioClient;

  ListingsService({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient(AuthService());

  Dio get _dio => _dioClient.dio;

  // ============================================================
  // Browse (public feed)
  // ============================================================

  Future<List<Listing>> getPublished({
    String? category,
    String? type,
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get(
        '/listings',
        queryParameters: {
          if (category != null) 'category': category,
          if (type != null) 'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final data = res.data['data'] as List<dynamic>;
      return data
          .map((j) => Listing.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ============================================================
  // My Listings
  // ============================================================

  Future<List<Listing>> getMyListings({
    String state = 'all',
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get(
        '/listings/my',
        queryParameters: {
          'state': state,
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final data = res.data['data'] as List<dynamic>;
      return data
          .map((j) => Listing.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ============================================================
  // Detail
  // ============================================================

  Future<Listing> getById(String id) async {
    try {
      final res = await _dio.get('/listings/$id');
      return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ============================================================
  // Create / Update
  // ============================================================

  Future<Listing> createDraft({
    required String title,
    String? description,
    ListingCategory? category,
    ListingType? type,
    num? price,
    String? swapPreference,
    ListingCondition? condition,
    List<String>? images,
    MeetingPoint? meetingPoint,
  }) async {
    try {
      final res = await _dio.post(
        '/listings',
        data: {
          'title': title,
          if (description != null) 'description': description,
          if (category != null) 'category': category.apiValue,
          if (type != null) 'type': type.apiValue,
          if (price != null) 'price': price,
          if (swapPreference != null) 'swapPreference': swapPreference,
          if (condition != null) 'condition': condition.apiValue,
          if (images != null) 'images': images,
          if (meetingPoint != null) 'meetingPoint': meetingPoint.toJson(),
        },
      );
      return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<Listing> update(
    String id, {
    String? title,
    String? description,
    ListingCategory? category,
    ListingType? type,
    num? price,
    String? swapPreference,
    ListingCondition? condition,
    List<String>? images,
    MeetingPoint? meetingPoint,
  }) async {
    try {
      final res = await _dio.patch(
        '/listings/$id',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (category != null) 'category': category.apiValue,
          if (type != null) 'type': type.apiValue,
          if (price != null) 'price': price,
          if (swapPreference != null) 'swapPreference': swapPreference,
          if (condition != null) 'condition': condition.apiValue,
          if (images != null) 'images': images,
          if (meetingPoint != null) 'meetingPoint': meetingPoint.toJson(),
        },
      );
      return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // 🎯 เพิ่มเมธอดนี้สำหรับเปลี่ยนสถานะโดยเฉพาะ
  Future<Listing> updateState(String id, String state) async {
    try {
      final res = await _dio.patch(
        '/listings/$id/state',
        data: {'state': state},
      );
      return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ============================================================
  // State transitions
  // ============================================================

  Future<Listing> publish(String id) async {
    try {
      final res = await _dio.post('/listings/$id/publish');
      return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> markSold(
    String id, {
    required String dealType,
    required String buyerLineId,
    required String dateCompleted,
    double? finalPrice,
    String? whatIGotReturn,
    String? swapItemPhotoURL,
  }) async {
    try {
      await _dio.post(
        '/listings/$id/sold',
        data: {
          'dealType': dealType,
          'buyerLineId': buyerLineId,
          'dateCompleted': dateCompleted,
          if (finalPrice != null) 'finalPrice': finalPrice,
          if (whatIGotReturn != null) 'whatIGotReturn': whatIGotReturn,
          if (swapItemPhotoURL != null) 'swapItemPhotoURL': swapItemPhotoURL,
        },
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/listings/$id');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ============================================================
  // ⭐ Smart Semantic Search (Gemini embeddings on backend)
  // ============================================================

  /// Smart search using Gemini embeddings + cosine similarity.
  /// "flower" finds "rose", "ดอกไม้", "bouquet" etc.
  ///
  /// Returns list sorted by relevance (highest score first).
  Future<List<SearchResult>> search({
    required String query,
    String? category,
    String? type,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.post(
        '/listings/search',
        data: {
          'query': query,
          if (category != null) 'category': category,
          if (type != null) 'type': type,
          'limit': limit,
        },
      );
      final data = res.data['data'] as List<dynamic>;
      return data
          .map((j) => SearchResult.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ============================================================
  // Error parsing
  // ============================================================

  String _parseError(DioException e) {
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      final errorObj = data['error'];
      if (errorObj is Map && errorObj['message'] is String) {
        return errorObj['message'] as String;
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Network error';
  }
}

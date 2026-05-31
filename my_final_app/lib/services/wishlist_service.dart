import 'package:dio/dio.dart';
import '../domain/entities/listing.dart';
import 'auth_service.dart';
import 'dio_client.dart';

/// Service for Wishlist API
class WishlistService {
  final DioClient _dioClient;

  /// Default constructor — uses DioClient with AuthService
  /// Same pattern as ListingsService.
  WishlistService({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient(AuthService());

  Dio get _dio => _dioClient.dio;

  // ============================================================
  // Get my wishlist
  // ============================================================

  Future<List<Listing>> getMyWishlist() async {
    try {
      final res = await _dio.get('/wishlist');
      final data = res.data['data'] as List<dynamic>;
      return data
          .map((j) => Listing.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ============================================================
  // Check membership
  // ============================================================

  Future<bool> isInWishlist(String listingId) async {
    try {
      final res = await _dio.get('/wishlist/check/$listingId');
      return res.data['data']['inWishlist'] as bool;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ============================================================
  // Add / Remove
  // ============================================================

  Future<void> add(String listingId) async {
    try {
      await _dio.post('/wishlist/$listingId');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> remove(String listingId) async {
    try {
      await _dio.delete('/wishlist/$listingId');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Convenience: toggle wishlist state
  /// Returns new state (true = now in wishlist, false = removed)
  Future<bool> toggle(String listingId) async {
    final current = await isInWishlist(listingId);
    if (current) {
      await remove(listingId);
      return false;
    } else {
      await add(listingId);
      return true;
    }
  }

  // ============================================================
  // Error parsing
  // ============================================================

  String _parseError(DioException e) {
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
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    return 'Network error';
  }
}

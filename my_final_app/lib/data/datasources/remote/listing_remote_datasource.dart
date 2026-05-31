import 'package:dio/dio.dart';
import '../../../domain/entities/listing.dart';
import '../../network/dio_client.dart';

class ListingRemoteDataSource {
  final DioClient _client;
  Dio get _dio => _client.dio;

  ListingRemoteDataSource(this._client);

  Future<List<Listing>> getPublished({
    String? category,
    String? type,
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
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
    return (res.data['data'] as List<dynamic>)
        .map((j) => Listing.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Listing>> getMyListings({
    String state = 'all',
    int limit = 20,
    String? cursor,
  }) async {
    final res = await _dio.get(
      '/listings/my',
      queryParameters: {
        'state': state,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return (res.data['data'] as List<dynamic>)
        .map((j) => Listing.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> getById(String id) async {
    final res = await _dio.get('/listings/$id');
    return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<SearchResult>> search({
    required String query,
    String? category,
    String? type,
    int limit = 20,
  }) async {
    final res = await _dio.post(
      '/listings/search',
      data: {
        'query': query,
        if (category != null) 'category': category,
        if (type != null) 'type': type,
        'limit': limit,
      },
    );
    return (res.data['data'] as List<dynamic>)
        .map((j) => SearchResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Listing> create({
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
    final res = await _dio.post('/listings', data: {
      'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category.apiValue,
      if (type != null) 'type': type.apiValue,
      if (price != null) 'price': price,
      if (swapPreference != null) 'swapPreference': swapPreference,
      if (condition != null) 'condition': condition.apiValue,
      if (images != null) 'images': images,
      if (meetingPoint != null) 'meetingPoint': meetingPoint.toJson(),
    });
    return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
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
    final res = await _dio.patch('/listings/$id', data: {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category.apiValue,
      if (type != null) 'type': type.apiValue,
      if (price != null) 'price': price,
      if (swapPreference != null) 'swapPreference': swapPreference,
      if (condition != null) 'condition': condition.apiValue,
      if (images != null) 'images': images,
      if (meetingPoint != null) 'meetingPoint': meetingPoint.toJson(),
    });
    return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Listing> publish(String id) async {
    final res = await _dio.post('/listings/$id/publish');
    return Listing.fromJson(res.data['data'] as Map<String, dynamic>);
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
    await _dio.post('/listings/$id/sold', data: {
      'dealType': dealType,
      'buyerLineId': buyerLineId,
      'dateCompleted': dateCompleted,
      if (finalPrice != null) 'finalPrice': finalPrice,
      if (whatIGotReturn != null) 'whatIGotReturn': whatIGotReturn,
      if (swapItemPhotoURL != null) 'swapItemPhotoURL': swapItemPhotoURL,
    });
  }

  Future<void> delete(String id) async {
    await _dio.delete('/listings/$id');
  }

  Future<List<Listing>> getMyWishlist() async {
    final res = await _dio.get('/wishlist');
    return (res.data['data'] as List<dynamic>)
        .map((j) => Listing.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isInWishlist(String listingId) async {
    final res = await _dio.get('/wishlist/check/$listingId');
    return res.data['data']['inWishlist'] as bool;
  }

  Future<void> addToWishlist(String listingId) async {
    await _dio.post('/wishlist/$listingId');
  }

  Future<void> removeFromWishlist(String listingId) async {
    await _dio.delete('/wishlist/$listingId');
  }
}

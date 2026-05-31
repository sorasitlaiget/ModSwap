import '../../domain/repositories/rating_repository.dart';
import '../datasources/remote/rating_remote_datasource.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingRemoteDataSource _ds;
  RatingRepositoryImpl(this._ds);

  @override
  Stream<List<Map<String, dynamic>>> watchPendingRatings(String uid) =>
      _ds.watchPendingRatings(uid);

  @override
  Future<String?> findBuyerUidByLineId(String lineId) =>
      _ds.findBuyerUidByLineId(lineId);

  @override
  Future<void> createPendingRating({
    required String buyerUid,
    required String sellerId,
    required String sellerName,
    required String listingId,
    required String listingTitle,
  }) =>
      _ds.createPendingRating(
        buyerUid: buyerUid,
        sellerId: sellerId,
        sellerName: sellerName,
        listingId: listingId,
        listingTitle: listingTitle,
      );

  @override
  Future<void> submitRating({
    required String pendingRatingId,
    required int rating,
  }) =>
      _ds.submitRating(pendingRatingId: pendingRatingId, rating: rating);

  @override
  Future<void> skipRating(String pendingRatingId) =>
      _ds.skipRating(pendingRatingId);
}

abstract interface class RatingRepository {
  Stream<List<Map<String, dynamic>>> watchPendingRatings(String uid);
  Future<String?> findBuyerUidByLineId(String lineId);
  Future<void> createPendingRating({
    required String buyerUid,
    required String sellerId,
    required String sellerName,
    required String listingId,
    required String listingTitle,
  });
  Future<void> submitRating({
    required String pendingRatingId,
    required int rating,
  });
  Future<void> skipRating(String pendingRatingId);
}

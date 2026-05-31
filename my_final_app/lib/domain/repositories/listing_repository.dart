import '../entities/listing.dart';

abstract interface class ListingRepository {
  Future<List<Listing>> getPublished({
    String? category,
    String? type,
    String? search,
    int limit = 20,
    String? cursor,
  });

  Future<List<Listing>> getMyListings({
    String state = 'all',
    int limit = 20,
    String? cursor,
  });

  Future<Listing> getById(String id);

  Future<List<SearchResult>> search({
    required String query,
    String? category,
    String? type,
    int limit = 20,
  });

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
  });

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
  });

  Future<Listing> publish(String id);

  Future<void> markSold(
    String id, {
    required String dealType,
    required String buyerLineId,
    required String dateCompleted,
    double? finalPrice,
    String? whatIGotReturn,
    String? swapItemPhotoURL,
  });

  Future<void> delete(String id);
}

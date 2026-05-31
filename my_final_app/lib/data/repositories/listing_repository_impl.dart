import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../datasources/remote/listing_remote_datasource.dart';

class ListingRepositoryImpl implements ListingRepository {
  final ListingRemoteDataSource _ds;
  ListingRepositoryImpl(this._ds);

  @override
  Future<List<Listing>> getPublished({
    String? category,
    String? type,
    String? search,
    int limit = 20,
    String? cursor,
  }) => _ds.getPublished(
    category: category,
    type: type,
    search: search,
    limit: limit,
    cursor: cursor,
  );

  @override
  Future<List<Listing>> getMyListings({
    String state = 'all',
    int limit = 20,
    String? cursor,
  }) => _ds.getMyListings(state: state, limit: limit, cursor: cursor);

  @override
  Future<Listing> getById(String id) => _ds.getById(id);

  @override
  Future<List<SearchResult>> search({
    required String query,
    String? category,
    String? type,
    int limit = 20,
  }) => _ds.search(query: query, category: category, type: type, limit: limit);

  @override
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
  }) => _ds.create(
    title: title,
    description: description,
    category: category,
    type: type,
    price: price,
    swapPreference: swapPreference,
    condition: condition,
    images: images,
    meetingPoint: meetingPoint,
  );

  @override
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
  }) => _ds.update(
    id,
    title: title,
    description: description,
    category: category,
    type: type,
    price: price,
    swapPreference: swapPreference,
    condition: condition,
    images: images,
    meetingPoint: meetingPoint,
  );

  @override
  Future<Listing> publish(String id) => _ds.publish(id);

  @override
  Future<void> markSold(
    String id, {
    required String dealType,
    required String buyerLineId,
    required String dateCompleted,
    double? finalPrice,
    String? whatIGotReturn,
    String? swapItemPhotoURL,
  }) => _ds.markSold(
    id,
    dealType: dealType,
    buyerLineId: buyerLineId,
    dateCompleted: dateCompleted,
    finalPrice: finalPrice,
    whatIGotReturn: whatIGotReturn,
    swapItemPhotoURL: swapItemPhotoURL,
  );

  @override
  Future<void> delete(String id) => _ds.delete(id);
}

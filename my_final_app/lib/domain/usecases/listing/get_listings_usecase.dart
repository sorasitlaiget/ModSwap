import '../../entities/listing.dart';
import '../../repositories/listing_repository.dart';

class GetListingsUseCase {
  final ListingRepository _repo;
  const GetListingsUseCase(this._repo);

  Future<List<Listing>> call({
    String? category,
    String? type,
    String? search,
    int limit = 20,
    String? cursor,
  }) =>
      _repo.getPublished(
        category: category,
        type: type,
        search: search,
        limit: limit,
        cursor: cursor,
      );
}

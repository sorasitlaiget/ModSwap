import '../../entities/listing.dart';
import '../../repositories/listing_repository.dart';

class GetListingByIdUseCase {
  final ListingRepository _repo;
  const GetListingByIdUseCase(this._repo);
  Future<Listing> call(String id) => _repo.getById(id);
}

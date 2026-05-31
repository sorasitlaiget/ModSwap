import '../../entities/listing.dart';
import '../../repositories/wishlist_repository.dart';

class GetWishlistUseCase {
  final WishlistRepository _repo;
  const GetWishlistUseCase(this._repo);
  Future<List<Listing>> call() => _repo.getMyWishlist();
}

import '../../repositories/wishlist_repository.dart';

class ToggleWishlistUseCase {
  final WishlistRepository _repo;
  const ToggleWishlistUseCase(this._repo);
  Future<bool> call(String listingId) => _repo.toggle(listingId);
}

import '../../domain/entities/listing.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/remote/listing_remote_datasource.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final ListingRemoteDataSource _ds;
  WishlistRepositoryImpl(this._ds);

  @override
  Future<List<Listing>> getMyWishlist() => _ds.getMyWishlist();

  @override
  Future<bool> isInWishlist(String listingId) => _ds.isInWishlist(listingId);

  @override
  Future<void> add(String listingId) => _ds.addToWishlist(listingId);

  @override
  Future<void> remove(String listingId) => _ds.removeFromWishlist(listingId);

  @override
  Future<bool> toggle(String listingId) async {
    final current = await _ds.isInWishlist(listingId);
    if (current) {
      await _ds.removeFromWishlist(listingId);
      return false;
    } else {
      await _ds.addToWishlist(listingId);
      return true;
    }
  }
}

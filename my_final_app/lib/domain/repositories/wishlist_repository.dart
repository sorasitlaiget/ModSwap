import '../entities/listing.dart';

abstract interface class WishlistRepository {
  Future<List<Listing>> getMyWishlist();
  Future<bool> isInWishlist(String listingId);
  Future<void> add(String listingId);
  Future<void> remove(String listingId);
  Future<bool> toggle(String listingId);
}

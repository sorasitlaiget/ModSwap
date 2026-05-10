import { ListingResponseDto } from '../../listings/dto/listings.dto';

/**
 * Single wishlist item response — full listing data + addedAt timestamp
 */
export interface WishlistItemResponseDto extends ListingResponseDto {
  addedAt: string; // ISO timestamp when user added to wishlist
}

/**
 * Check response: whether listing is in user's wishlist
 */
export interface WishlistCheckResponseDto {
  listingId: string;
  inWishlist: boolean;
}

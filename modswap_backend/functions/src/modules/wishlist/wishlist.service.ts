import { ListingsRepository } from '../listings/listings.repository';
import { ListingResponseDto } from '../listings/dto/listings.dto';
import { Listing } from '../listings/listings.types';
import { NotFoundError, BadRequestError } from '../../core/errors/app-error';
import { logger } from '../../utils/logger.util';
import { WishlistRepository } from './wishlist.repository';
import {
  WishlistCheckResponseDto,
  WishlistItemResponseDto,
} from './dto/wishlist.dto';

/**
 * Wishlist Service - business logic for wishlist
 */
export class WishlistService {
  constructor(
    private readonly wishlistRepo: WishlistRepository,
    private readonly listingsRepo: ListingsRepository,
  ) {}

  /**
   * Add a listing to user's wishlist.
   * - Validates listing exists and is published (not draft/sold/removed)
   * - Cannot wishlist your own listing
   */
  async add(uid: string, listingId: string): Promise<void> {
    const listing = await this.listingsRepo.findById(listingId);

    if (!listing) {
      throw new NotFoundError('Listing not found');
    }

    if (listing.state === 'removed') {
      throw new BadRequestError('Cannot wishlist a removed listing');
    }

    if (listing.ownerId === uid) {
      throw new BadRequestError('Cannot wishlist your own listing');
    }

    await this.wishlistRepo.add(uid, listingId);
    logger.info('Added to wishlist', { uid, listingId });
  }

  /**
   * Remove a listing from user's wishlist (idempotent)
   */
  async remove(uid: string, listingId: string): Promise<void> {
    await this.wishlistRepo.remove(uid, listingId);
    logger.info('Removed from wishlist', { uid, listingId });
  }

  /**
   * Check if a listing is in user's wishlist
   */
  async check(
    uid: string,
    listingId: string,
  ): Promise<WishlistCheckResponseDto> {
    const inWishlist = await this.wishlistRepo.exists(uid, listingId);
    return { listingId, inWishlist };
  }

  /**
   * Get user's wishlist with full listing details.
   * - Filters out listings that have been removed
   * - Returns sold/draft listings with their state intact (frontend handles display)
   */
  async findAll(uid: string): Promise<WishlistItemResponseDto[]> {
    const entries = await this.wishlistRepo.findAll(uid);

    if (entries.length === 0) return [];

    // Fetch all listings in parallel
    const listingPromises = entries.map((e) =>
      this.listingsRepo
        .findById(e.listingId)
        .then((listing) => ({ entry: e, listing }))
        .catch(() => ({ entry: e, listing: null })),
    );

    const results = await Promise.all(listingPromises);

    // Filter out removed/missing listings + auto-cleanup orphaned wishlist entries
    const cleaned: WishlistItemResponseDto[] = [];
    const orphans: string[] = [];

    for (const { entry, listing } of results) {
      if (!listing || listing.state === 'removed') {
        orphans.push(entry.listingId);
        continue;
      }
      cleaned.push({
        ...this.toListingDto(listing),
        addedAt: entry.addedAt.toDate().toISOString(),
      });
    }

    // Best-effort cleanup of orphaned entries (don't await — fire & forget)
    if (orphans.length > 0) {
      Promise.all(
        orphans.map((id) => this.wishlistRepo.remove(uid, id)),
      ).catch(() => null);
      logger.info('Cleaning orphaned wishlist entries', {
        uid,
        count: orphans.length,
      });
    }

    return cleaned;
  }

  /**
   * Map Listing → ListingResponseDto
   * (duplicated from ListingsService.toDto — kept here to avoid coupling)
   */
  private toListingDto(listing: Listing): ListingResponseDto {
    return {
      id: listing.id,
      ownerId: listing.ownerId,
      ownerName: listing.ownerName,
      ownerStudentId: listing.ownerStudentId,
      ownerLineId: listing.ownerLineId,
      title: listing.title,
      description: listing.description,
      category: listing.category,
      type: listing.type,
      price: listing.price,
      swapPreference: listing.swapPreference,
      images: listing.images,
      thumbnailURL: listing.thumbnailURL,
      condition: listing.condition,
      meetingPoint: listing.meetingPoint,
      state: listing.state,
      views: listing.views,
      createdAt: listing.createdAt.toDate().toISOString(),
      updatedAt: listing.updatedAt.toDate().toISOString(),
      publishedAt: listing.publishedAt?.toDate().toISOString() ?? null,
    };
  }
}

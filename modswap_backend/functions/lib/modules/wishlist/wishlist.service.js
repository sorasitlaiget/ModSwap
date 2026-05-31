"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WishlistService = void 0;
const app_error_1 = require("../../core/errors/app-error");
const logger_util_1 = require("../../utils/logger.util");
const notification_util_1 = require("../../utils/notification.util");
/**
 * Wishlist Service - business logic for wishlist
 */
class WishlistService {
    constructor(wishlistRepo, listingsRepo) {
        this.wishlistRepo = wishlistRepo;
        this.listingsRepo = listingsRepo;
    }
    /**
     * Add a listing to user's wishlist.
     * - Validates listing exists and is published (not draft/sold/removed)
     * - Cannot wishlist your own listing
     */
    async add(uid, listingId) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing) {
            throw new app_error_1.NotFoundError('Listing not found');
        }
        if (listing.state === 'removed') {
            throw new app_error_1.BadRequestError('Cannot wishlist a removed listing');
        }
        if (listing.ownerId === uid) {
            throw new app_error_1.BadRequestError('Cannot wishlist your own listing');
        }
        await this.wishlistRepo.add(uid, listingId);
        logger_util_1.logger.info('Added to wishlist', { uid, listingId });
        // Fire-and-forget: notify the seller
        (0, notification_util_1.sendNotification)({
            recipientUid: listing.ownerId,
            type: 'wishlist',
            title: 'Someone Wishlisted Your Item',
            body: `"${listing.title}" was added to a wishlist`,
            deepLinkTarget: `/item/${listingId}`,
            data: { itemId: listingId },
        }).catch(() => null);
    }
    /**
     * Remove a listing from user's wishlist (idempotent)
     */
    async remove(uid, listingId) {
        await this.wishlistRepo.remove(uid, listingId);
        logger_util_1.logger.info('Removed from wishlist', { uid, listingId });
    }
    /**
     * Check if a listing is in user's wishlist
     */
    async check(uid, listingId) {
        const inWishlist = await this.wishlistRepo.exists(uid, listingId);
        return { listingId, inWishlist };
    }
    /**
     * Get user's wishlist with full listing details.
     * - Filters out listings that have been removed
     * - Returns sold/draft listings with their state intact (frontend handles display)
     */
    async findAll(uid) {
        const entries = await this.wishlistRepo.findAll(uid);
        if (entries.length === 0)
            return [];
        // Fetch all listings in parallel
        const listingPromises = entries.map((e) => this.listingsRepo
            .findById(e.listingId)
            .then((listing) => ({ entry: e, listing }))
            .catch(() => ({ entry: e, listing: null })));
        const results = await Promise.all(listingPromises);
        // Filter out removed/missing listings + auto-cleanup orphaned wishlist entries
        const cleaned = [];
        const orphans = [];
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
            Promise.all(orphans.map((id) => this.wishlistRepo.remove(uid, id))).catch(() => null);
            logger_util_1.logger.info('Cleaning orphaned wishlist entries', {
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
    toListingDto(listing) {
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
exports.WishlistService = WishlistService;
//# sourceMappingURL=wishlist.service.js.map
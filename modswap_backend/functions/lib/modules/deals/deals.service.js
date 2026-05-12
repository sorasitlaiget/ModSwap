"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DealsService = void 0;
const firestore_1 = require("firebase-admin/firestore");
const app_error_1 = require("../../core/errors/app-error");
const logger_util_1 = require("../../utils/logger.util");
class DealsService {
    constructor(dealsRepo, listingsRepo, usersRepo) {
        this.dealsRepo = dealsRepo;
        this.listingsRepo = listingsRepo;
        this.usersRepo = usersRepo;
    }
    /**
     * Mark a published listing as sold and record the deal details.
     * Steps:
     *   1. Validate listing exists, belongs to caller, and is published
     *   2. Guard against duplicate deal records
     *   3. Create deal document
     *   4. Flip listing state → 'sold'
     *   5. Increment seller's totalTrades
     */
    async markAsSold(uid, listingId, dto) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing)
            throw new app_error_1.NotFoundError('Listing not found');
        if (listing.ownerId !== uid) {
            throw new app_error_1.ForbiddenError('You can only mark your own listings as sold');
        }
        if (listing.state !== 'published') {
            throw new app_error_1.BadRequestError('Only published listings can be marked as sold');
        }
        const existing = await this.dealsRepo.findByListingId(listingId);
        if (existing) {
            throw new app_error_1.ConflictError('This listing already has a deal record');
        }
        const deal = await this.dealsRepo.create({
            listingId,
            sellerId: uid,
            dealType: dto.dealType,
            buyerLineId: dto.buyerLineId,
            dateCompleted: firestore_1.Timestamp.fromDate(new Date(dto.dateCompleted)),
            finalPrice: dto.finalPrice ?? null,
            whatIGotReturn: dto.whatIGotReturn ?? null,
            swapItemPhotoURL: dto.swapItemPhotoURL ?? null,
        });
        await this.listingsRepo.update(listingId, { state: 'sold' });
        await this.usersRepo.incrementTotalTrades(uid);
        logger_util_1.logger.info('Listing marked as sold', {
            uid,
            listingId,
            dealId: deal.id,
            dealType: dto.dealType,
        });
        const updatedListing = await this.listingsRepo.findById(listingId);
        return {
            deal: this.dealToDto(deal),
            listing: this.listingToDto(updatedListing),
        };
    }
    /**
     * Get the deal record for a sold listing (owner only)
     */
    async getDealByListingId(uid, listingId) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing)
            throw new app_error_1.NotFoundError('Listing not found');
        if (listing.ownerId !== uid) {
            throw new app_error_1.ForbiddenError('You can only view deals for your own listings');
        }
        const deal = await this.dealsRepo.findByListingId(listingId);
        if (!deal)
            throw new app_error_1.NotFoundError('No deal record found for this listing');
        return this.dealToDto(deal);
    }
    dealToDto(deal) {
        return {
            id: deal.id,
            listingId: deal.listingId,
            sellerId: deal.sellerId,
            dealType: deal.dealType,
            buyerLineId: deal.buyerLineId,
            dateCompleted: deal.dateCompleted.toDate().toISOString(),
            finalPrice: deal.finalPrice,
            whatIGotReturn: deal.whatIGotReturn,
            swapItemPhotoURL: deal.swapItemPhotoURL,
            createdAt: deal.createdAt.toDate().toISOString(),
        };
    }
    listingToDto(listing) {
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
exports.DealsService = DealsService;
//# sourceMappingURL=deals.service.js.map
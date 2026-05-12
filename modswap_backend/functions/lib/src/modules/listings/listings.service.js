"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListingsService = void 0;
const firestore_1 = require("firebase-admin/firestore");
const app_error_1 = require("../../core/errors/app-error");
const logger_util_1 = require("../../utils/logger.util");
const listings_validator_1 = require("./listings.validator");
/**
 * Listings Service - business logic for listings
 */
class ListingsService {
    constructor(listingsRepo, usersRepo) {
        this.listingsRepo = listingsRepo;
        this.usersRepo = usersRepo;
    }
    async createDraft(uid, dto) {
        const owner = await this.usersRepo.findById(uid);
        if (!owner)
            throw new app_error_1.NotFoundError('User profile not found');
        const isProfileComplete = !!(owner.studentId &&
            owner.lineId &&
            owner.faculty);
        if (!isProfileComplete) {
            throw new app_error_1.ForbiddenError('Please complete your profile before posting listings');
        }
        const images = dto.images ?? [];
        const listing = await this.listingsRepo.create({
            ownerId: uid,
            ownerName: owner.displayName,
            ownerStudentId: owner.studentId ?? '',
            ownerLineId: owner.lineId ?? '',
            title: dto.title,
            description: dto.description ?? null,
            category: dto.category ?? null,
            type: dto.type ?? null,
            price: dto.price ?? null,
            swapPreference: dto.swapPreference ?? null,
            condition: dto.condition ?? null,
            images,
            thumbnailURL: images.length > 0 ? images[0] : null,
            meetingPoint: dto.meetingPoint ?? null,
            state: 'draft',
            views: 0,
            publishedAt: null,
        });
        logger_util_1.logger.info('Draft listing created', { uid, listingId: listing.id });
        return this.toDto(listing);
    }
    async update(uid, listingId, dto) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing)
            throw new app_error_1.NotFoundError('Listing not found');
        if (listing.ownerId !== uid) {
            throw new app_error_1.ForbiddenError('You can only edit your own listings');
        }
        if (listing.state === 'removed') {
            throw new app_error_1.ForbiddenError('Cannot edit a removed listing');
        }
        const updates = {};
        if (dto.title !== undefined)
            updates.title = dto.title;
        if (dto.description !== undefined)
            updates.description = dto.description;
        if (dto.category !== undefined)
            updates.category = dto.category;
        if (dto.type !== undefined)
            updates.type = dto.type;
        if (dto.price !== undefined)
            updates.price = dto.price;
        if (dto.swapPreference !== undefined) {
            updates.swapPreference = dto.swapPreference;
        }
        if (dto.condition !== undefined)
            updates.condition = dto.condition;
        if (dto.meetingPoint !== undefined) {
            updates.meetingPoint = dto.meetingPoint;
        }
        if (dto.images !== undefined) {
            updates.images = dto.images;
            updates.thumbnailURL = dto.images.length > 0 ? dto.images[0] : null;
        }
        await this.listingsRepo.update(listingId, updates);
        logger_util_1.logger.info('Listing updated', { uid, listingId });
        const updated = await this.listingsRepo.findById(listingId);
        return this.toDto(updated);
    }
    /**
     * Publish a draft → published (validates full schema)
     */
    async publish(uid, listingId) {
        return this.changeState(uid, listingId, 'published');
    }
    /**
     * Mark listing as sold (only from published)
     */
    async markSold(uid, listingId) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing)
            throw new app_error_1.NotFoundError('Listing not found');
        if (listing.state !== 'published') {
            throw new app_error_1.BadRequestError('Only published listings can be marked as sold');
        }
        return this.changeState(uid, listingId, 'sold');
    }
    /**
     * Change listing state to one of: draft, published, sold
     * - Owner only
     * - Cannot change to/from 'removed' (use DELETE endpoint)
     * - When → published: must pass full validation
     * - When → draft or sold: no field validation needed
     */
    async changeState(uid, listingId, newState) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing) {
            throw new app_error_1.NotFoundError('Listing not found');
        }
        if (listing.ownerId !== uid) {
            throw new app_error_1.ForbiddenError('You can only modify your own listings');
        }
        if (listing.state === 'removed') {
            throw new app_error_1.ForbiddenError('Cannot modify a removed listing');
        }
        // Same state — no-op
        if (listing.state === newState) {
            return this.toDto(listing);
        }
        // When → 'published', validate full schema
        if (newState === 'published') {
            const result = listings_validator_1.publishListingSchema.safeParse({
                title: listing.title,
                description: listing.description,
                category: listing.category,
                type: listing.type,
                price: listing.price,
                swapPreference: listing.swapPreference,
                condition: listing.condition,
                images: listing.images,
                meetingPoint: listing.meetingPoint,
            });
            if (!result.success) {
                const issues = result.error.issues.map((i) => i.message).join('; ');
                throw new app_error_1.BadRequestError(`Cannot publish: ${issues}. Please complete all required fields.`);
            }
        }
        // Build update payload
        const updates = {
            state: newState,
        };
        // Set publishedAt only on first publish (preserve original timestamp
        // when going sold → published → sold for analytics consistency)
        if (newState === 'published' && listing.publishedAt === null) {
            updates.publishedAt = firestore_1.Timestamp.now();
        }
        await this.listingsRepo.update(listingId, updates);
        logger_util_1.logger.info('Listing state changed', {
            uid,
            listingId,
            from: listing.state,
            to: newState,
        });
        const updated = await this.listingsRepo.findById(listingId);
        return this.toDto(updated);
    }
    async delete(uid, listingId) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing)
            throw new app_error_1.NotFoundError('Listing not found');
        if (listing.ownerId !== uid) {
            throw new app_error_1.ForbiddenError('You can only delete your own listings');
        }
        await this.listingsRepo.softDelete(listingId);
        logger_util_1.logger.info('Listing soft deleted', { uid, listingId });
    }
    async getById(listingId, viewerId) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing)
            throw new app_error_1.NotFoundError('Listing not found');
        if (listing.state === 'draft' || listing.state === 'removed') {
            if (listing.ownerId !== viewerId) {
                throw new app_error_1.NotFoundError('Listing not found');
            }
        }
        else if (viewerId) {
            await this.recordView(listingId, viewerId);
            if (listing.ownerId !== viewerId && listing.state === 'published') {
                listing.views += 1;
            }
        }
        return this.toDto(listing);
    }
    async recordView(listingId, viewerId) {
        const listing = await this.listingsRepo.findById(listingId);
        if (!listing)
            return;
        if (listing.ownerId === viewerId)
            return;
        if (listing.state !== 'published')
            return;
        await this.listingsRepo.incrementViews(listingId);
    }
    async findPublished(query) {
        const listings = await this.listingsRepo.findPublished({
            category: query.category,
            type: query.type,
            search: query.search,
            limit: query.limit ?? 20,
            cursor: query.cursor,
        });
        return listings.map((l) => this.toDto(l));
    }
    async findMyListings(uid, query) {
        const stateFilter = !query.state || query.state === 'all' ? undefined : query.state;
        const listings = await this.listingsRepo.findByOwner({
            ownerId: uid,
            state: stateFilter,
            limit: query.limit ?? 20,
            cursor: query.cursor,
        });
        return listings.map((l) => this.toDto(l));
    }
    toDto(listing) {
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
exports.ListingsService = ListingsService;
//# sourceMappingURL=listings.service.js.map
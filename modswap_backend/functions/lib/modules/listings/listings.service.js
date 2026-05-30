"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListingsService = void 0;
const crypto = __importStar(require("crypto"));
const firestore_1 = require("firebase-admin/firestore");
const app_error_1 = require("../../core/errors/app-error");
const logger_util_1 = require("../../utils/logger.util");
const notification_util_1 = require("../../utils/notification.util");
const firebase_config_1 = require("../../config/firebase.config");
const constants_1 = require("../../config/constants");
const listings_validator_1 = require("./listings.validator");
const embedding_util_1 = require("../../utils/embedding.util");
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
            // Embedding generated only on publish (saves API calls on drafts)
            embedding: null,
            embeddingHash: null,
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
        // ⭐ Re-embed if embedding-relevant fields changed AND listing is published
        const embeddingFieldsChanged = dto.title !== undefined ||
            dto.description !== undefined ||
            dto.category !== undefined ||
            dto.condition !== undefined;
        if (embeddingFieldsChanged && listing.state === 'published') {
            const fresh = await this.listingsRepo.findById(listingId);
            if (fresh) {
                this.refreshEmbedding(fresh).catch((err) => logger_util_1.logger.error('Embedding refresh failed', { err, listingId }));
            }
        }
        logger_util_1.logger.info('Listing updated', { uid, listingId });
        // Fire-and-forget: notify wishlist users if price dropped
        if (dto.price != null &&
            listing.price != null &&
            dto.price < listing.price) {
            this.notifyPriceDrop(listingId, listing.title, listing.price, dto.price).catch(() => null);
        }
        const updated = await this.listingsRepo.findById(listingId);
        return this.toDto(updated);
    }
    async notifyPriceDrop(listingId, title, oldPrice, newPrice) {
        const snap = await firebase_config_1.db
            .collectionGroup(constants_1.SUBCOLLECTIONS.WISHLIST)
            .where('listingId', '==', listingId)
            .get();
        const notifications = snap.docs.map((doc) => {
            const uid = doc.ref.parent.parent?.id;
            if (!uid)
                return Promise.resolve();
            return (0, notification_util_1.sendNotification)({
                recipientUid: uid,
                type: 'priceDrop',
                title: 'Price Drop on Wishlist',
                body: `"${title}" is now ฿${newPrice.toLocaleString()} (was ฿${oldPrice.toLocaleString()})`,
                deepLinkTarget: `/item/${listingId}`,
                data: { listingId, oldPrice, newPrice },
            });
        });
        await Promise.all(notifications);
        logger_util_1.logger.info('Price drop notifications sent', { listingId, count: snap.size });
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
        // ⭐ Generate embedding when transitioning to published
        if (newState === 'published') {
            this.refreshEmbedding(listing).catch((err) => logger_util_1.logger.error('Embedding generation failed', { err, listingId }));
        }
        logger_util_1.logger.info('Listing state changed', {
            uid,
            listingId,
            from: listing.state,
            to: newState,
        });
        const updated = await this.listingsRepo.findById(listingId);
        return this.toDto(updated);
    }
    // ============================================================
    // ⭐ Semantic Search
    // ============================================================
    /**
     * Smart search using Gemini embeddings + cosine similarity.
     * "flower" → finds "rose", "ดอกไม้", "bouquet", etc.
     */
    async search(params) {
        const query = params.query.trim();
        if (!query)
            return [];
        const limit = params.limit ?? 20;
        const minScore = params.minScore ?? 0.6;
        // 1. Embed the query
        const queryEmbedding = await (0, embedding_util_1.embedQuery)(query);
        if (!queryEmbedding) {
            logger_util_1.logger.warn('Query embedding failed — falling back to keyword search');
            const fallback = await this.findPublished({
                search: query,
                category: params.category,
                type: params.type,
                limit,
            });
            return fallback.map((l) => ({ ...l, score: 0 }));
        }
        // 2. Fetch candidate published listings
        const candidates = await this.listingsRepo.findPublished({
            category: params.category,
            type: params.type,
            limit: 500,
        });
        if (candidates.length === 0)
            return [];
        // 3. Rank by cosine similarity
        const scored = candidates
            .filter((l) => l.embedding && l.embedding.length > 0)
            .map((listing) => ({
            listing,
            score: (0, embedding_util_1.cosineSimilarity)(queryEmbedding, listing.embedding),
        }))
            .filter((s) => s.score >= minScore)
            .sort((a, b) => b.score - a.score)
            .slice(0, limit);
        logger_util_1.logger.info('Semantic search', {
            query,
            candidates: candidates.length,
            results: scored.length,
            topScore: scored[0]?.score ?? 0,
        });
        return scored.map(({ listing, score }) => ({
            ...this.toDto(listing),
            score,
        }));
    }
    /**
     * Regenerate embedding for a listing.
     * Skips API call if content hash hasn't changed.
     */
    async refreshEmbedding(listing) {
        const text = (0, embedding_util_1.buildEmbedText)({
            title: listing.title,
            description: listing.description,
            category: listing.category,
            condition: listing.condition,
        });
        if (!text) {
            logger_util_1.logger.warn('No text to embed', { listingId: listing.id });
            return;
        }
        const hash = crypto.createHash('sha256').update(text).digest('hex');
        if (listing.embeddingHash === hash && listing.embedding?.length) {
            return;
        }
        const embedding = await (0, embedding_util_1.embedDocument)(text);
        if (!embedding) {
            logger_util_1.logger.error('Failed to generate embedding', { listingId: listing.id });
            return;
        }
        await this.listingsRepo.update(listing.id, {
            embedding,
            embeddingHash: hash,
        });
        logger_util_1.logger.info('Embedding refreshed', {
            listingId: listing.id,
            dims: embedding.length,
        });
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
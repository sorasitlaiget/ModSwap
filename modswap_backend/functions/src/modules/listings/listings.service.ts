import * as crypto from 'crypto';
import { Timestamp } from 'firebase-admin/firestore';
import { ListingsRepository } from './listings.repository';
import { UsersRepository } from '../users/users.repository';
import {
  ForbiddenError,
  NotFoundError,
  BadRequestError,
} from '../../core/errors/app-error';
import { logger } from '../../utils/logger.util';
import { sendNotification } from '../../utils/notification.util';
import { db } from '../../config/firebase.config';
import { SUBCOLLECTIONS } from '../../config/constants';
import { publishListingSchema } from './listings.validator';
import {
  CreateDraftDto,
  ListingResponseDto,
  ListingsQueryDto,
  MyListingsQueryDto,
  UpdateListingDto,
} from './dto/listings.dto';
import { Listing, ListingState } from './listings.types';
import {
  buildEmbedText,
  cosineSimilarity,
  embedDocument,
  embedQuery,
} from '../../utils/embedding.util';

/**
 * Listings Service - business logic for listings
 */
export class ListingsService {
  constructor(
    private readonly listingsRepo: ListingsRepository,
    private readonly usersRepo: UsersRepository,
  ) {}

  async createDraft(
    uid: string,
    dto: CreateDraftDto,
  ): Promise<ListingResponseDto> {
    const owner = await this.usersRepo.findById(uid);
    if (!owner) throw new NotFoundError('User profile not found');

    const isProfileComplete = !!(
      owner.studentId &&
      owner.lineId &&
      owner.faculty
    );
    if (!isProfileComplete) {
      throw new ForbiddenError(
        'Please complete your profile before posting listings',
      );
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

    logger.info('Draft listing created', { uid, listingId: listing.id });
    return this.toDto(listing);
  }

  async update(
    uid: string,
    listingId: string,
    dto: UpdateListingDto,
  ): Promise<ListingResponseDto> {
    const listing = await this.listingsRepo.findById(listingId);
    if (!listing) throw new NotFoundError('Listing not found');
    if (listing.ownerId !== uid) {
      throw new ForbiddenError('You can only edit your own listings');
    }
    if (listing.state === 'removed') {
      throw new ForbiddenError('Cannot edit a removed listing');
    }

    const updates: any = {};
    if (dto.title !== undefined) updates.title = dto.title;
    if (dto.description !== undefined) updates.description = dto.description;
    if (dto.category !== undefined) updates.category = dto.category;
    if (dto.type !== undefined) updates.type = dto.type;
    if (dto.price !== undefined) updates.price = dto.price;
    if (dto.swapPreference !== undefined) {
      updates.swapPreference = dto.swapPreference;
    }
    if (dto.condition !== undefined) updates.condition = dto.condition;
    if (dto.meetingPoint !== undefined) {
      updates.meetingPoint = dto.meetingPoint;
    }
    if (dto.images !== undefined) {
      updates.images = dto.images;
      updates.thumbnailURL = dto.images.length > 0 ? dto.images[0] : null;
    }

    await this.listingsRepo.update(listingId, updates);

    // ⭐ Re-embed if embedding-relevant fields changed AND listing is published
    const embeddingFieldsChanged =
      dto.title !== undefined ||
      dto.description !== undefined ||
      dto.category !== undefined ||
      dto.condition !== undefined;

    if (embeddingFieldsChanged && listing.state === 'published') {
      const fresh = await this.listingsRepo.findById(listingId);
      if (fresh) {
        this.refreshEmbedding(fresh).catch((err) =>
          logger.error('Embedding refresh failed', { err, listingId }),
        );
      }
    }

    logger.info('Listing updated', { uid, listingId });

    // Fire-and-forget: notify wishlist users if price dropped
    if (
      dto.price != null &&
      listing.price != null &&
      dto.price < listing.price
    ) {
      this.notifyPriceDrop(listingId, listing.title, listing.price, dto.price).catch(() => null);
    }

    const updated = await this.listingsRepo.findById(listingId);
    return this.toDto(updated!);
  }

  private async notifyPriceDrop(
    listingId: string,
    title: string,
    oldPrice: number,
    newPrice: number,
  ): Promise<void> {
    const snap = await db
      .collectionGroup(SUBCOLLECTIONS.WISHLIST)
      .where('listingId', '==', listingId)
      .get();

    const notifications = snap.docs.map((doc) => {
      const uid = doc.ref.parent.parent?.id;
      if (!uid) return Promise.resolve();
      return sendNotification({
        recipientUid: uid,
        type: 'priceDrop',
        title: 'Price Drop on Wishlist',
        body: `"${title}" is now ฿${newPrice.toLocaleString()} (was ฿${oldPrice.toLocaleString()})`,
        deepLinkTarget: `/item/${listingId}`,
        data: { listingId, oldPrice, newPrice },
      });
    });

    await Promise.all(notifications);
    logger.info('Price drop notifications sent', { listingId, count: snap.size });
  }

  /**
   * Publish a draft → published (validates full schema)
   */
  async publish(uid: string, listingId: string): Promise<ListingResponseDto> {
    return this.changeState(uid, listingId, 'published');
  }

  /**
   * Mark listing as sold (only from published)
   */
  async markSold(
    uid: string,
    listingId: string,
  ): Promise<ListingResponseDto> {
    const listing = await this.listingsRepo.findById(listingId);
    if (!listing) throw new NotFoundError('Listing not found');
    if (listing.state !== 'published') {
      throw new BadRequestError(
        'Only published listings can be marked as sold',
      );
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
  async changeState(
    uid: string,
    listingId: string,
    newState: 'draft' | 'published' | 'sold',
  ): Promise<ListingResponseDto> {
    const listing = await this.listingsRepo.findById(listingId);

    if (!listing) {
      throw new NotFoundError('Listing not found');
    }

    if (listing.ownerId !== uid) {
      throw new ForbiddenError('You can only modify your own listings');
    }

    if (listing.state === 'removed') {
      throw new ForbiddenError('Cannot modify a removed listing');
    }

    // Same state — no-op
    if (listing.state === newState) {
      return this.toDto(listing);
    }

    // When → 'published', validate full schema
    if (newState === 'published') {
      const result = publishListingSchema.safeParse({
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
        throw new BadRequestError(
          `Cannot publish: ${issues}. Please complete all required fields.`,
        );
      }
    }

    // Build update payload
    const updates: { state: ListingState; publishedAt?: Timestamp } = {
      state: newState,
    };

    // Set publishedAt only on first publish (preserve original timestamp
    // when going sold → published → sold for analytics consistency)
    if (newState === 'published' && listing.publishedAt === null) {
      updates.publishedAt = Timestamp.now();
    }

    await this.listingsRepo.update(listingId, updates);

    // ⭐ Generate embedding when transitioning to published
    if (newState === 'published') {
      this.refreshEmbedding(listing).catch((err) =>
        logger.error('Embedding generation failed', { err, listingId }),
      );
    }

    logger.info('Listing state changed', {
      uid,
      listingId,
      from: listing.state,
      to: newState,
    });

    const updated = await this.listingsRepo.findById(listingId);
    return this.toDto(updated!);
  }

  // ============================================================
  // ⭐ Semantic Search
  // ============================================================

  /**
   * Smart search using Gemini embeddings + cosine similarity.
   * "flower" → finds "rose", "ดอกไม้", "bouquet", etc.
   */
  async search(params: {
    query: string;
    category?: string;
    type?: string;
    limit?: number;
    minScore?: number;
  }): Promise<Array<ListingResponseDto & { score: number }>> {
    const query = params.query.trim();
    if (!query) return [];

    const limit = params.limit ?? 20;
    const minScore = params.minScore ?? 0.62;

    // 1. Embed the query
    const queryEmbedding = await embedQuery(query);
    if (!queryEmbedding) {
      logger.warn('Query embedding failed — falling back to keyword search');
      const fallback = await this.findPublished({
        search: query,
        category: params.category as any,
        type: params.type as any,
        limit,
      });
      return fallback.map((l) => ({ ...l, score: 0 }));
    }

    // 2. Fetch candidate published listings
    const candidates = await this.listingsRepo.findPublished({
      category: params.category as any,
      type: params.type as any,
      limit: 500,
    });

    if (candidates.length === 0) return [];

    // 3. Rank by cosine similarity
    const scored = candidates
      .filter((l) => l.embedding && l.embedding.length > 0)
      .map((listing) => ({
        listing,
        score: cosineSimilarity(queryEmbedding, listing.embedding!),
      }))
      .filter((s) => s.score >= minScore)
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);

    logger.info('Semantic search', {
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
  private async refreshEmbedding(listing: Listing): Promise<void> {
    const text = buildEmbedText({
      title: listing.title,
      description: listing.description,
      category: listing.category,
      condition: listing.condition,
    });

    if (!text) {
      logger.warn('No text to embed', { listingId: listing.id });
      return;
    }

    const hash = crypto.createHash('sha256').update(text).digest('hex');

    if (listing.embeddingHash === hash && listing.embedding?.length) {
      return;
    }

    const embedding = await embedDocument(text);
    if (!embedding) {
      logger.error('Failed to generate embedding', { listingId: listing.id });
      return;
    }

    await this.listingsRepo.update(listing.id, {
      embedding,
      embeddingHash: hash,
    });

    logger.info('Embedding refreshed', {
      listingId: listing.id,
      dims: embedding.length,
    });
  }

  async delete(uid: string, listingId: string): Promise<void> {
    const listing = await this.listingsRepo.findById(listingId);
    if (!listing) throw new NotFoundError('Listing not found');
    if (listing.ownerId !== uid) {
      throw new ForbiddenError('You can only delete your own listings');
    }
    await this.listingsRepo.softDelete(listingId);
    logger.info('Listing soft deleted', { uid, listingId });
  }

  async getById(
    listingId: string,
    viewerId?: string,
  ): Promise<ListingResponseDto> {
    const listing = await this.listingsRepo.findById(listingId);
    if (!listing) throw new NotFoundError('Listing not found');

    if (listing.state === 'draft' || listing.state === 'removed') {
      if (listing.ownerId !== viewerId) {
        throw new NotFoundError('Listing not found');
      }
    } else if (viewerId) {
      await this.recordView(listingId, viewerId);
      if (listing.ownerId !== viewerId && listing.state === 'published') {
        listing.views += 1;
      }
    }

    return this.toDto(listing);
  }

  async recordView(listingId: string, viewerId: string): Promise<void> {
    const listing = await this.listingsRepo.findById(listingId);
    if (!listing) return;
    if (listing.ownerId === viewerId) return;
    if (listing.state !== 'published') return;
    await this.listingsRepo.incrementViews(listingId);
  }

  async findPublished(
    query: ListingsQueryDto,
  ): Promise<ListingResponseDto[]> {
    const listings = await this.listingsRepo.findPublished({
      category: query.category,
      type: query.type,
      search: query.search,
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
    return listings.map((l) => this.toDto(l));
  }

  async findMyListings(
    uid: string,
    query: MyListingsQueryDto,
  ): Promise<ListingResponseDto[]> {
    const stateFilter =
      !query.state || query.state === 'all' ? undefined : query.state;
    const listings = await this.listingsRepo.findByOwner({
      ownerId: uid,
      state: stateFilter,
      limit: query.limit ?? 20,
      cursor: query.cursor,
    });
    return listings.map((l) => this.toDto(l));
  }

  private toDto(listing: Listing): ListingResponseDto {
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

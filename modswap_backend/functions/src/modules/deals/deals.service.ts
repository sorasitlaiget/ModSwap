import { Timestamp } from 'firebase-admin/firestore';
import { DealsRepository } from './deals.repository';
import { ListingsRepository } from '../listings/listings.repository';
import { UsersRepository } from '../users/users.repository';
import {
  BadRequestError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../core/errors/app-error';
import { logger } from '../../utils/logger.util';
import { Deal } from './deals.types';
import { Listing } from '../listings/listings.types';
import {
  DealResponseDto,
  MarkAsSoldDto,
  MarkAsSoldResponseDto,
} from './dto/deals.dto';
import { ListingResponseDto } from '../listings/dto/listings.dto';

export class DealsService {
  constructor(
    private readonly dealsRepo: DealsRepository,
    private readonly listingsRepo: ListingsRepository,
    private readonly usersRepo: UsersRepository,
  ) {}

  /**
   * Mark a published listing as sold and record the deal details.
   * Steps:
   *   1. Validate listing exists, belongs to caller, and is published
   *   2. Guard against duplicate deal records
   *   3. Create deal document
   *   4. Flip listing state → 'sold'
   *   5. Increment seller's totalTrades
   */
  async markAsSold(
    uid: string,
    listingId: string,
    dto: MarkAsSoldDto,
  ): Promise<MarkAsSoldResponseDto> {
    const listing = await this.listingsRepo.findById(listingId);
    if (!listing) throw new NotFoundError('Listing not found');

    if (listing.ownerId !== uid) {
      throw new ForbiddenError('You can only mark your own listings as sold');
    }

    if (listing.state !== 'published') {
      throw new BadRequestError('Only published listings can be marked as sold');
    }

    const existing = await this.dealsRepo.findByListingId(listingId);
    if (existing) {
      throw new ConflictError('This listing already has a deal record');
    }

    const deal = await this.dealsRepo.create({
      listingId,
      sellerId: uid,
      dealType: dto.dealType,
      buyerLineId: dto.buyerLineId,
      dateCompleted: Timestamp.fromDate(new Date(dto.dateCompleted)),
      finalPrice: dto.finalPrice ?? null,
      whatIGotReturn: dto.whatIGotReturn ?? null,
      swapItemPhotoURL: dto.swapItemPhotoURL ?? null,
    });

    await this.listingsRepo.update(listingId, { state: 'sold' });
    await this.usersRepo.incrementTotalTrades(uid);

    logger.info('Listing marked as sold', {
      uid,
      listingId,
      dealId: deal.id,
      dealType: dto.dealType,
    });

    const updatedListing = await this.listingsRepo.findById(listingId);
    return {
      deal: this.dealToDto(deal),
      listing: this.listingToDto(updatedListing!),
    };
  }

  /**
   * Get the deal record for a sold listing (owner only)
   */
  async getDealByListingId(
    uid: string,
    listingId: string,
  ): Promise<DealResponseDto> {
    const listing = await this.listingsRepo.findById(listingId);
    if (!listing) throw new NotFoundError('Listing not found');

    if (listing.ownerId !== uid) {
      throw new ForbiddenError('You can only view deals for your own listings');
    }

    const deal = await this.dealsRepo.findByListingId(listingId);
    if (!deal) throw new NotFoundError('No deal record found for this listing');

    return this.dealToDto(deal);
  }

  private dealToDto(deal: Deal): DealResponseDto {
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

  private listingToDto(listing: Listing): ListingResponseDto {
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

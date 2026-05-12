import { DealType } from '../deals.types';
import { ListingResponseDto } from '../../listings/dto/listings.dto';

/**
 * Input DTO for POST /listings/:id/sold
 */
export interface MarkAsSoldDto {
  dealType: DealType;
  buyerLineId: string;
  dateCompleted: string; // YYYY-MM-DD
  finalPrice?: number | null;
  whatIGotReturn?: string | null;
  swapItemPhotoURL?: string | null;
}

/**
 * API response shape for a deal (Timestamps serialized as ISO strings)
 */
export interface DealResponseDto {
  id: string;
  listingId: string;
  sellerId: string;
  dealType: DealType;
  buyerLineId: string;
  dateCompleted: string;
  finalPrice: number | null;
  whatIGotReturn: string | null;
  swapItemPhotoURL: string | null;
  createdAt: string;
}

/**
 * Response returned when marking a listing as sold
 */
export interface MarkAsSoldResponseDto {
  deal: DealResponseDto;
  listing: ListingResponseDto;
}

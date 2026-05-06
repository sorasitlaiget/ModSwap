import type {
  ListingCategory,
  ListingCondition,
  ListingState,
  ListingType,
  MeetingPoint,
} from '../listings.types';

/**
 * DTO for creating a draft listing (input from API)
 */
export interface CreateDraftDto {
  title: string;
  description?: string | null;
  category?: ListingCategory | null;
  type?: ListingType | null;
  price?: number | null;
  swapPreference?: string | null;
  condition?: ListingCondition | null;
  images?: string[];
  meetingPoint?: MeetingPoint | null;
}

/**
 * DTO for updating a listing (partial)
 */
export interface UpdateListingDto {
  title?: string;
  description?: string | null;
  category?: ListingCategory | null;
  type?: ListingType | null;
  price?: number | null;
  swapPreference?: string | null;
  condition?: ListingCondition | null;
  images?: string[];
  meetingPoint?: MeetingPoint | null;
}

/**
 * Query params for browse listings
 */
export interface ListingsQueryDto {
  category?: ListingCategory;
  type?: ListingType;
  search?: string;
  limit?: number;
  cursor?: string;
}

/**
 * Query params for "my listings"
 */
export interface MyListingsQueryDto {
  state?: 'draft' | 'published' | 'sold' | 'all';
  limit?: number;
  cursor?: string;
}

/**
 * API Response shape (Timestamps as ISO strings)
 */
export interface ListingResponseDto {
  id: string;
  ownerId: string;
  ownerName: string;
  ownerStudentId: string;
  ownerLineId: string;
  title: string;
  description: string | null;
  category: ListingCategory | null;
  type: ListingType | null;
  price: number | null;
  swapPreference: string | null;
  images: string[];
  thumbnailURL: string | null;
  condition: ListingCondition | null;
  meetingPoint: MeetingPoint | null;
  state: ListingState;
  views: number;
  createdAt: string;
  updatedAt: string;
  publishedAt: string | null;
}

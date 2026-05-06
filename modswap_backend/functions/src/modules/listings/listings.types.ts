import { Timestamp } from 'firebase-admin/firestore';

/**
 * Listing Domain Model
 */
export const LISTING_CATEGORIES = [
  'textbooks',
  'electronics',
  'fashion',
  'dorm',
  'vehicles',
  'others',
] as const;
export type ListingCategory = (typeof LISTING_CATEGORIES)[number];

export const LISTING_TYPES = ['sell', 'trade', 'both'] as const;
export type ListingType = (typeof LISTING_TYPES)[number];

export const LISTING_CONDITIONS = ['new', 'like-new', 'used'] as const;
export type ListingCondition = (typeof LISTING_CONDITIONS)[number];

export const LISTING_STATES = [
  'draft',
  'published',
  'sold',
  'removed',
] as const;
export type ListingState = (typeof LISTING_STATES)[number];

/**
 * Constraints
 */
export const MAX_IMAGES_PER_LISTING = 10;
export const MIN_IMAGES_FOR_PUBLISH = 1;

/**
 * KMUTT Bangmod campus bounds
 */
export const KMUTT_BOUNDS = {
  minLat: 13.640,
  maxLat: 13.660,
  minLng: 100.485,
  maxLng: 100.510,
} as const;

/**
 * Meeting point — within KMUTT campus
 */
export interface MeetingPoint {
  name: string;
  latitude: number;
  longitude: number;
  placeId: string | null;
}

/**
 * Listing Domain Model — represents document in Firestore
 */
export interface Listing {
  id: string;

  // Owner (denormalized for fast read)
  ownerId: string;
  ownerName: string;
  ownerStudentId: string;
  ownerLineId: string;

  // Content
  title: string;
  description: string | null;
  category: ListingCategory | null;
  type: ListingType | null;

  // Pricing & swap
  price: number | null;
  swapPreference: string | null;

  // Images
  images: string[];
  thumbnailURL: string | null;

  // Item info
  condition: ListingCondition | null;

  // Meeting point
  meetingPoint: MeetingPoint | null;

  // State
  state: ListingState;

  // Stats
  views: number;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
  publishedAt: Timestamp | null;
}

/**
 * Data used to create a new listing (in repository)
 */
export type CreateListingData = Omit<Listing, 'id' | 'createdAt' | 'updatedAt'>;

/**
 * Data used to update a listing (in repository)
 */
export type UpdateListingData = Partial<
  Pick<
    Listing,
    | 'title'
    | 'description'
    | 'category'
    | 'type'
    | 'price'
    | 'swapPreference'
    | 'condition'
    | 'images'
    | 'thumbnailURL'
    | 'meetingPoint'
    | 'state'
    | 'publishedAt'
  >
>;

/**
 * Helper: check if coordinates are within KMUTT
 */
export function isWithinKmutt(lat: number, lng: number): boolean {
  return (
    lat >= KMUTT_BOUNDS.minLat &&
    lat <= KMUTT_BOUNDS.maxLat &&
    lng >= KMUTT_BOUNDS.minLng &&
    lng <= KMUTT_BOUNDS.maxLng
  );
}

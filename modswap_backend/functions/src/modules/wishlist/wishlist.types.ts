import { Timestamp } from 'firebase-admin/firestore';

/**
 * Wishlist entry stored in Firestore
 * Path: users/{uid}/wishlist/{listingId}
 */
export interface WishlistEntry {
  listingId: string;
  addedAt: Timestamp;
}

/**
 * Subcollection name (under each user document)
 */
export const WISHLIST_SUBCOLLECTION = 'wishlist';

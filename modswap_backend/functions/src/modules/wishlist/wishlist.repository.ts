import { firestore } from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { COLLECTIONS } from '../../config/constants';
import { WISHLIST_SUBCOLLECTION, WishlistEntry } from './wishlist.types';

/**
 * Wishlist Repository
 *
 * Path layout: users/{uid}/wishlist/{listingId}
 *
 * Document ID = listingId (so we can quickly check existence
 * and prevent duplicates without an extra query).
 */
export class WishlistRepository {
  private db = firestore();

  private collection(uid: string) {
    return this.db
      .collection(COLLECTIONS.USERS)
      .doc(uid)
      .collection(WISHLIST_SUBCOLLECTION);
  }

  /**
   * Add a listing to user's wishlist (idempotent — overwrites if exists)
   */
  async add(uid: string, listingId: string): Promise<void> {
    const entry: WishlistEntry = {
      listingId,
      addedAt: Timestamp.now(),
    };
    await this.collection(uid).doc(listingId).set(entry);
  }

  /**
   * Remove a listing from user's wishlist
   */
  async remove(uid: string, listingId: string): Promise<void> {
    await this.collection(uid).doc(listingId).delete();
  }

  /**
   * Check whether a listing is in user's wishlist
   */
  async exists(uid: string, listingId: string): Promise<boolean> {
    const doc = await this.collection(uid).doc(listingId).get();
    return doc.exists;
  }

  /**
   * List all wishlist entries for a user, newest first
   */
  async findAll(uid: string, limit = 100): Promise<WishlistEntry[]> {
    const snapshot = await this.collection(uid)
      .orderBy('addedAt', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map((d) => d.data() as WishlistEntry);
  }
}

import { Timestamp, FieldValue } from 'firebase-admin/firestore';
import { firestore } from '../../config/firebase.config';
import { COLLECTIONS } from '../../config/constants';
import {
  Listing,
  CreateListingData,
  UpdateListingData,
  ListingState,
} from './listings.types';

/**
 * Listings Repository - manages Firestore collection 'listings'
 * No business logic here - pure data access
 */
export class ListingsRepository {
  private readonly collection = firestore.collection(COLLECTIONS.LISTINGS);

  /**
   * Create a new listing
   * Repository sets createdAt/updatedAt automatically
   */
  async create(data: CreateListingData): Promise<Listing> {
    const docRef = this.collection.doc();
    const now = Timestamp.now();
    const listing: Listing = {
      ...data,
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
    };
    await docRef.set(listing);
    return listing;
  }

  async findById(id: string): Promise<Listing | null> {
    const doc = await this.collection.doc(id).get();
    if (!doc.exists) return null;
    return doc.data() as Listing;
  }

  async update(id: string, data: UpdateListingData): Promise<void> {
    await this.collection.doc(id).update({
      ...data,
      updatedAt: Timestamp.now(),
    });
  }

  /**
   * Soft delete (state = 'removed')
   * Real cleanup happens in trigger
   */
  async softDelete(id: string): Promise<void> {
    await this.collection.doc(id).update({
      state: 'removed' as ListingState,
      updatedAt: Timestamp.now(),
    });
  }

  /**
   * Hard delete (used by trigger after image cleanup)
   */
  async hardDelete(id: string): Promise<void> {
    await this.collection.doc(id).delete();
  }

  /**
   * Increment view counter atomically
   */
  async incrementViews(id: string): Promise<void> {
    await this.collection.doc(id).update({
      views: FieldValue.increment(1),
    });
  }

  /**
   * Find published listings (Home feed)
   */
  async findPublished(options: {
    category?: string;
    type?: string;
    search?: string;
    limit: number;
    cursor?: string;
  }): Promise<Listing[]> {
    let query = this.collection
      .where('state', '==', 'published')
      .orderBy('publishedAt', 'desc')
      .limit(options.limit);

    if (options.category) {
      query = query.where('category', '==', options.category);
    }

    if (options.type) {
      query = query.where('type', '==', options.type);
    }

    if (options.cursor) {
      const cursorDoc = await this.collection.doc(options.cursor).get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    const snap = await query.get();
    let listings = snap.docs.map((d) => d.data() as Listing);

    // In-memory search filter
    if (options.search) {
      const q = options.search.toLowerCase();
      listings = listings.filter(
        (l) =>
          l.title.toLowerCase().includes(q) ||
          (l.description?.toLowerCase().includes(q) ?? false),
      );
    }

    return listings;
  }

  /**
   * Find listings by owner
   */
  async findByOwner(options: {
    ownerId: string;
    state?: 'draft' | 'published' | 'sold';
    limit: number;
    cursor?: string;
  }): Promise<Listing[]> {
    let query = options.state
      ? this.collection
          .where('ownerId', '==', options.ownerId)
          .where('state', '==', options.state)
          .orderBy('createdAt', 'desc')
          .limit(options.limit)
      : this.collection
          .where('ownerId', '==', options.ownerId)
          .where('state', '!=', 'removed')
          .orderBy('state')
          .orderBy('createdAt', 'desc')
          .limit(options.limit);

    if (options.cursor) {
      const cursorDoc = await this.collection.doc(options.cursor).get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    const snap = await query.get();
    return snap.docs.map((d) => d.data() as Listing);
  }
}

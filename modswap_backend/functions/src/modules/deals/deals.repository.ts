import { Timestamp } from 'firebase-admin/firestore';
import { firestore } from '../../config/firebase.config';
import { COLLECTIONS } from '../../config/constants';
import { Deal, CreateDealData } from './deals.types';

/**
 * Deals Repository — pure data access for 'deals' collection
 */
export class DealsRepository {
  private readonly collection = firestore.collection(COLLECTIONS.DEALS);

  async create(data: CreateDealData): Promise<Deal> {
    const docRef = this.collection.doc();
    const now = Timestamp.now();
    const deal: Deal = {
      ...data,
      id: docRef.id,
      createdAt: now,
    };
    await docRef.set(deal);
    return deal;
  }

  async findById(id: string): Promise<Deal | null> {
    const doc = await this.collection.doc(id).get();
    if (!doc.exists) return null;
    return doc.data() as Deal;
  }

  /**
   * Each listing can have at most one deal record
   */
  async findByListingId(listingId: string): Promise<Deal | null> {
    const snap = await this.collection
      .where('listingId', '==', listingId)
      .limit(1)
      .get();
    if (snap.empty) return null;
    return snap.docs[0].data() as Deal;
  }
}

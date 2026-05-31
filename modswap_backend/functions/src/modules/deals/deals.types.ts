import { Timestamp } from 'firebase-admin/firestore';

export const DEAL_TYPES = ['cash', 'swap', 'swap_cash'] as const;
export type DealType = (typeof DEAL_TYPES)[number];

/**
 * Deal Domain Model — represents document in Firestore 'deals' collection
 * Created when a seller marks a listing as sold
 */
export interface Deal {
  id: string;
  listingId: string;
  sellerId: string;

  dealType: DealType;
  buyerLineId: string;
  dateCompleted: Timestamp;

  // cash or swap_cash only
  finalPrice: number | null;

  // swap or swap_cash only
  whatIGotReturn: string | null;
  swapItemPhotoURL: string | null;

  createdAt: Timestamp;
}

export type CreateDealData = Omit<Deal, 'id' | 'createdAt'>;

export interface PendingRating {
  id: string;
  buyerUid: string;
  sellerId: string;
  sellerName: string;
  listingId: string;
  listingTitle: string;
  createdAt: Timestamp;
}

export type CreatePendingRatingData = Omit<PendingRating, 'id' | 'createdAt'>;

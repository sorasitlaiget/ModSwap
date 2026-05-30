import { Router } from 'express';
import { z } from 'zod';
import { FieldValue } from 'firebase-admin/firestore';
import { authMiddleware } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validation.middleware';
import { firestore } from '../../config/firebase.config';
import { COLLECTIONS } from '../../config/constants';
import { successResponse } from '../../utils/response.util';
import {
  ForbiddenError,
  NotFoundError,
} from '../../core/errors/app-error';
import { sendNotification } from '../../utils/notification.util';

const submitRatingSchema = z.object({
  pendingRatingId: z.string().min(1),
  rating: z.number().int().min(1).max(5),
});

export function createRatingsRouter(): Router {
  const router = Router();

  /**
   * POST /ratings
   * Submit a star rating for a seller.
   * Body: { pendingRatingId, rating (1-5) }
   * - Verifies the pending rating belongs to the caller
   * - Updates seller's weighted average rating + totalReviews atomically
   * - Deletes the pending rating document
   */
  router.post('/', authMiddleware, validateBody(submitRatingSchema), async (req, res, next) => {
    try {
      const uid = (req as any).uid as string;
      const { pendingRatingId, rating } = req.body as {
        pendingRatingId: string;
        rating: number;
      };

      const pendingRef = firestore.collection(COLLECTIONS.PENDING_RATINGS).doc(pendingRatingId);

      let sellerId = '';
      let listingTitle = '';

      await firestore.runTransaction(async (tx) => {
        const pendingDoc = await tx.get(pendingRef);
        if (!pendingDoc.exists) throw new NotFoundError('Pending rating not found');

        const pending = pendingDoc.data()!;
        if (pending.buyerUid !== uid) throw new ForbiddenError('This rating request does not belong to you');

        sellerId = pending.sellerId;
        listingTitle = pending.listingTitle ?? '';

        const sellerRef = firestore.collection(COLLECTIONS.USERS).doc(pending.sellerId);
        const sellerDoc = await tx.get(sellerRef);
        if (!sellerDoc.exists) throw new NotFoundError('Seller not found');

        const seller = sellerDoc.data()!;
        const oldRating: number = seller.rating ?? 0;
        const totalReviews: number = seller.totalReviews ?? 0;
        const newRating = totalReviews === 0
          ? rating
          : (oldRating * totalReviews + rating) / (totalReviews + 1);

        tx.update(sellerRef, {
          rating: newRating,
          totalReviews: FieldValue.increment(1),
        });
        tx.delete(pendingRef);
      });

      // Notify seller they received a rating (fire-and-forget)
      if (sellerId) {
        sendNotification({
          recipientUid: sellerId,
          type: 'ratingReceived',
          title: 'New Rating Received',
          body: listingTitle
            ? `You received a ${rating}-star rating for "${listingTitle}".`
            : `You received a ${rating}-star rating.`,
        }).catch(() => null);
      }

      res.json(successResponse({ message: 'Rating submitted' }));
    } catch (err) {
      next(err);
    }
  });

  /**
   * DELETE /ratings/:pendingRatingId
   * Skip / dismiss a pending rating without submitting a score.
   */
  router.delete('/:pendingRatingId', authMiddleware, async (req, res, next) => {
    try {
      const uid = (req as any).uid as string;
      const { pendingRatingId } = req.params;

      const pendingRef = firestore.collection(COLLECTIONS.PENDING_RATINGS).doc(pendingRatingId);
      const pendingDoc = await pendingRef.get();

      if (!pendingDoc.exists) {
        res.json(successResponse({ message: 'Already dismissed' }));
        return;
      }

      if (pendingDoc.data()!.buyerUid !== uid) {
        throw new ForbiddenError('This rating request does not belong to you');
      }

      await pendingRef.delete();
      res.json(successResponse({ message: 'Rating skipped' }));
    } catch (err) {
      next(err);
    }
  });

  return router;
}

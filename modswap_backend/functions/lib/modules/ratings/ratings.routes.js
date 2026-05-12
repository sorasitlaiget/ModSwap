"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createRatingsRouter = createRatingsRouter;
const express_1 = require("express");
const zod_1 = require("zod");
const firestore_1 = require("firebase-admin/firestore");
const auth_middleware_1 = require("../../middleware/auth.middleware");
const validation_middleware_1 = require("../../middleware/validation.middleware");
const firebase_config_1 = require("../../config/firebase.config");
const constants_1 = require("../../config/constants");
const response_util_1 = require("../../utils/response.util");
const app_error_1 = require("../../core/errors/app-error");
const submitRatingSchema = zod_1.z.object({
    pendingRatingId: zod_1.z.string().min(1),
    rating: zod_1.z.number().int().min(1).max(5),
});
function createRatingsRouter() {
    const router = (0, express_1.Router)();
    /**
     * POST /ratings
     * Submit a star rating for a seller.
     * Body: { pendingRatingId, rating (1-5) }
     * - Verifies the pending rating belongs to the caller
     * - Updates seller's weighted average rating + totalReviews atomically
     * - Deletes the pending rating document
     */
    router.post('/', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(submitRatingSchema), async (req, res, next) => {
        try {
            const uid = req.uid;
            const { pendingRatingId, rating } = req.body;
            const pendingRef = firebase_config_1.firestore.collection(constants_1.COLLECTIONS.PENDING_RATINGS).doc(pendingRatingId);
            await firebase_config_1.firestore.runTransaction(async (tx) => {
                const pendingDoc = await tx.get(pendingRef);
                if (!pendingDoc.exists)
                    throw new app_error_1.NotFoundError('Pending rating not found');
                const pending = pendingDoc.data();
                if (pending.buyerUid !== uid)
                    throw new app_error_1.ForbiddenError('This rating request does not belong to you');
                const sellerRef = firebase_config_1.firestore.collection(constants_1.COLLECTIONS.USERS).doc(pending.sellerId);
                const sellerDoc = await tx.get(sellerRef);
                if (!sellerDoc.exists)
                    throw new app_error_1.NotFoundError('Seller not found');
                const seller = sellerDoc.data();
                const oldRating = seller.rating ?? 0;
                const totalReviews = seller.totalReviews ?? 0;
                const newRating = totalReviews === 0
                    ? rating
                    : (oldRating * totalReviews + rating) / (totalReviews + 1);
                tx.update(sellerRef, {
                    rating: newRating,
                    totalReviews: firestore_1.FieldValue.increment(1),
                });
                tx.delete(pendingRef);
            });
            res.json((0, response_util_1.successResponse)({ message: 'Rating submitted' }));
        }
        catch (err) {
            next(err);
        }
    });
    /**
     * DELETE /ratings/:pendingRatingId
     * Skip / dismiss a pending rating without submitting a score.
     */
    router.delete('/:pendingRatingId', auth_middleware_1.authMiddleware, async (req, res, next) => {
        try {
            const uid = req.uid;
            const { pendingRatingId } = req.params;
            const pendingRef = firebase_config_1.firestore.collection(constants_1.COLLECTIONS.PENDING_RATINGS).doc(pendingRatingId);
            const pendingDoc = await pendingRef.get();
            if (!pendingDoc.exists) {
                res.json((0, response_util_1.successResponse)({ message: 'Already dismissed' }));
                return;
            }
            if (pendingDoc.data().buyerUid !== uid) {
                throw new app_error_1.ForbiddenError('This rating request does not belong to you');
            }
            await pendingRef.delete();
            res.json((0, response_util_1.successResponse)({ message: 'Rating skipped' }));
        }
        catch (err) {
            next(err);
        }
    });
    return router;
}
//# sourceMappingURL=ratings.routes.js.map
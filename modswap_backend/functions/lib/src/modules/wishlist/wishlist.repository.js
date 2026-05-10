"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WishlistRepository = void 0;
const firebase_admin_1 = require("firebase-admin");
const firestore_1 = require("firebase-admin/firestore");
const constants_1 = require("../../config/constants");
const wishlist_types_1 = require("./wishlist.types");
/**
 * Wishlist Repository
 *
 * Path layout: users/{uid}/wishlist/{listingId}
 *
 * Document ID = listingId (so we can quickly check existence
 * and prevent duplicates without an extra query).
 */
class WishlistRepository {
    constructor() {
        this.db = (0, firebase_admin_1.firestore)();
    }
    collection(uid) {
        return this.db
            .collection(constants_1.COLLECTIONS.USERS)
            .doc(uid)
            .collection(wishlist_types_1.WISHLIST_SUBCOLLECTION);
    }
    /**
     * Add a listing to user's wishlist (idempotent — overwrites if exists)
     */
    async add(uid, listingId) {
        const entry = {
            listingId,
            addedAt: firestore_1.Timestamp.now(),
        };
        await this.collection(uid).doc(listingId).set(entry);
    }
    /**
     * Remove a listing from user's wishlist
     */
    async remove(uid, listingId) {
        await this.collection(uid).doc(listingId).delete();
    }
    /**
     * Check whether a listing is in user's wishlist
     */
    async exists(uid, listingId) {
        const doc = await this.collection(uid).doc(listingId).get();
        return doc.exists;
    }
    /**
     * List all wishlist entries for a user, newest first
     */
    async findAll(uid, limit = 100) {
        const snapshot = await this.collection(uid)
            .orderBy('addedAt', 'desc')
            .limit(limit)
            .get();
        return snapshot.docs.map((d) => d.data());
    }
}
exports.WishlistRepository = WishlistRepository;
//# sourceMappingURL=wishlist.repository.js.map
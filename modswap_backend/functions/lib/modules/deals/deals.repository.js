"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DealsRepository = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firebase_config_1 = require("../../config/firebase.config");
const constants_1 = require("../../config/constants");
/**
 * Deals Repository — pure data access for 'deals' collection
 */
class DealsRepository {
    constructor() {
        this.collection = firebase_config_1.firestore.collection(constants_1.COLLECTIONS.DEALS);
    }
    async create(data) {
        const docRef = this.collection.doc();
        const now = firestore_1.Timestamp.now();
        const deal = {
            ...data,
            id: docRef.id,
            createdAt: now,
        };
        await docRef.set(deal);
        return deal;
    }
    async findById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists)
            return null;
        return doc.data();
    }
    /**
     * Each listing can have at most one deal record
     */
    async findByListingId(listingId) {
        const snap = await this.collection
            .where('listingId', '==', listingId)
            .limit(1)
            .get();
        if (snap.empty)
            return null;
        return snap.docs[0].data();
    }
}
exports.DealsRepository = DealsRepository;
//# sourceMappingURL=deals.repository.js.map
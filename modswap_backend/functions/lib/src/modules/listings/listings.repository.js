"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListingsRepository = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firebase_config_1 = require("../../config/firebase.config");
const constants_1 = require("../../config/constants");
/**
 * Listings Repository - manages Firestore collection 'listings'
 * No business logic here - pure data access
 */
class ListingsRepository {
    constructor() {
        this.collection = firebase_config_1.firestore.collection(constants_1.COLLECTIONS.LISTINGS);
    }
    /**
     * Create a new listing
     * Repository sets createdAt/updatedAt automatically
     */
    async create(data) {
        const docRef = this.collection.doc();
        const now = firestore_1.Timestamp.now();
        const listing = {
            ...data,
            id: docRef.id,
            createdAt: now,
            updatedAt: now,
        };
        await docRef.set(listing);
        return listing;
    }
    async findById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists)
            return null;
        return doc.data();
    }
    async update(id, data) {
        await this.collection.doc(id).update({
            ...data,
            updatedAt: firestore_1.Timestamp.now(),
        });
    }
    /**
     * Soft delete (state = 'removed')
     * Real cleanup happens in trigger
     */
    async softDelete(id) {
        await this.collection.doc(id).update({
            state: 'removed',
            updatedAt: firestore_1.Timestamp.now(),
        });
    }
    /**
     * Hard delete (used by trigger after image cleanup)
     */
    async hardDelete(id) {
        await this.collection.doc(id).delete();
    }
    /**
     * Increment view counter atomically
     */
    async incrementViews(id) {
        await this.collection.doc(id).update({
            views: firestore_1.FieldValue.increment(1),
        });
    }
    /**
     * Find published listings (Home feed)
     */
    async findPublished(options) {
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
        let listings = snap.docs.map((d) => d.data());
        // In-memory search filter
        if (options.search) {
            const q = options.search.toLowerCase();
            listings = listings.filter((l) => l.title.toLowerCase().includes(q) ||
                (l.description?.toLowerCase().includes(q) ?? false));
        }
        return listings;
    }
    /**
     * Find listings by owner
     */
    async findByOwner(options) {
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
        return snap.docs.map((d) => d.data());
    }
}
exports.ListingsRepository = ListingsRepository;
//# sourceMappingURL=listings.repository.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onListingRemoved = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const storage_1 = require("firebase-admin/storage");
const v2_1 = require("firebase-functions/v2");
/**
 * Trigger: when a listing's state changes to 'removed'
 * → Delete all images from Storage
 * → Hard delete the document
 *
 * We listen on 'updated' (not 'deleted') because we use soft delete
 * (set state='removed') in the service.
 */
exports.onListingRemoved = (0, firestore_1.onDocumentUpdated)({
    document: 'listings/{listingId}',
    region: 'asia-southeast1',
}, async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    // Only act when state transitions to 'removed'
    if (before.state === 'removed' || after.state !== 'removed') {
        return;
    }
    const { listingId } = event.params;
    v2_1.logger.info(`[onListingRemoved] Cleaning up listing ${listingId}`);
    // 1. Delete images from Storage
    const bucket = (0, storage_1.getStorage)().bucket();
    const prefix = `listings/${after.ownerId}/${listingId}/`;
    try {
        const [files] = await bucket.getFiles({ prefix });
        v2_1.logger.info(`[onListingRemoved] Deleting ${files.length} files from ${prefix}`);
        await Promise.all(files.map((f) => f.delete().catch(() => null)));
    }
    catch (err) {
        v2_1.logger.error(`[onListingRemoved] Failed to delete storage files: ${err}`);
        // Continue to hard delete the document anyway
    }
    // 2. Hard delete the Firestore document
    try {
        await event.data?.after.ref.delete();
        v2_1.logger.info(`[onListingRemoved] Hard deleted document ${listingId}`);
    }
    catch (err) {
        v2_1.logger.error(`[onListingRemoved] Failed to hard delete document: ${err}`);
    }
});
//# sourceMappingURL=on-listing-delete.trigger.js.map
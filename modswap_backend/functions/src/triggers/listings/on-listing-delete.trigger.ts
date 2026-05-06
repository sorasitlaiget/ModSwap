import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions/v2';
import type { Listing } from '../../modules/listings/listings.types';

/**
 * Trigger: when a listing's state changes to 'removed'
 * → Delete all images from Storage
 * → Hard delete the document
 *
 * We listen on 'updated' (not 'deleted') because we use soft delete
 * (set state='removed') in the service.
 */
export const onListingRemoved = onDocumentUpdated(
  {
    document: 'listings/{listingId}',
    region: 'asia-southeast1',
  },
  async (event) => {
    const before = event.data?.before.data() as Listing | undefined;
    const after = event.data?.after.data() as Listing | undefined;

    if (!before || !after) return;

    // Only act when state transitions to 'removed'
    if (before.state === 'removed' || after.state !== 'removed') {
      return;
    }

    const { listingId } = event.params;
    logger.info(`[onListingRemoved] Cleaning up listing ${listingId}`);

    // 1. Delete images from Storage
    const bucket = getStorage().bucket();
    const prefix = `listings/${after.ownerId}/${listingId}/`;

    try {
      const [files] = await bucket.getFiles({ prefix });
      logger.info(
        `[onListingRemoved] Deleting ${files.length} files from ${prefix}`,
      );

      await Promise.all(files.map((f) => f.delete().catch(() => null)));
    } catch (err) {
      logger.error(
        `[onListingRemoved] Failed to delete storage files: ${err}`,
      );
      // Continue to hard delete the document anyway
    }

    // 2. Hard delete the Firestore document
    try {
      await event.data?.after.ref.delete();
      logger.info(`[onListingRemoved] Hard deleted document ${listingId}`);
    } catch (err) {
      logger.error(
        `[onListingRemoved] Failed to hard delete document: ${err}`,
      );
    }
  },
);

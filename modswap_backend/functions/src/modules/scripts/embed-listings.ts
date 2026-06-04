import * as crypto from 'crypto';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import {
  buildEmbedText,
  embedDocument,
} from '../../utils/embedding.util';

/**
 * Migration: Generate embeddings for existing published listings
 *
 * Run with:
 *   cd functions
 *   npx ts-node src/scripts/embed-listings.ts
 *
 * Or for emulator:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
 *   GEMINI_API_KEY=your-key \
 *   npx ts-node src/scripts/embed-listings.ts
 */

async function main() {
  initializeApp();
  const db = getFirestore();

  console.log('Fetching published listings without embeddings...');

  // Get all published listings
  const snapshot = await db
    .collection('listings')
    .where('state', '==', 'published')
    .get();

  console.log(`Found ${snapshot.size} published listings`);

  let processed = 0;
  let skipped = 0;
  let failed = 0;

  for (const doc of snapshot.docs) {
    const listing = doc.data();

    const text = buildEmbedText({
      title: listing.title,
      description: listing.description,
      category: listing.category,
      condition: listing.condition,
    });

    if (!text) {
      console.log(`Skip ${doc.id}: no text`);
      skipped++;
      continue;
    }

    const hash = crypto.createHash('sha256').update(text).digest('hex');

    // Skip if already embedded with same hash
    if (
      listing.embeddingHash === hash &&
      Array.isArray(listing.embedding) &&
      listing.embedding.length > 0
    ) {
      console.log(`Skip ${doc.id}: already embedded`);
      skipped++;
      continue;
    }

    console.log(`Embedding ${doc.id}: "${listing.title}"`);

    try {
      const embedding = await embedDocument(text);
      if (!embedding) {
        console.log(`Failed ${doc.id}: embedding returned null`);
        failed++;
        continue;
      }

      await doc.ref.update({
        embedding,
        embeddingHash: hash,
      });

      console.log(`  ✓ Saved (${embedding.length} dims)`);
      processed++;

      // Rate limit: stay under 1500 RPM (Gemini free tier)
      await new Promise((resolve) => setTimeout(resolve, 100));
    } catch (err) {
      console.error(`Failed ${doc.id}:`, err);
      failed++;
    }
  }

  console.log('---');
  console.log(`Done. Processed: ${processed}, Skipped: ${skipped}, Failed: ${failed}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

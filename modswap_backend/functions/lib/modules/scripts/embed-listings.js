"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const crypto = __importStar(require("crypto"));
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const embedding_util_1 = require("../../utils/embedding.util");
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
    (0, app_1.initializeApp)();
    const db = (0, firestore_1.getFirestore)();
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
        const text = (0, embedding_util_1.buildEmbedText)({
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
        if (listing.embeddingHash === hash &&
            Array.isArray(listing.embedding) &&
            listing.embedding.length > 0) {
            console.log(`Skip ${doc.id}: already embedded`);
            skipped++;
            continue;
        }
        console.log(`Embedding ${doc.id}: "${listing.title}"`);
        try {
            const embedding = await (0, embedding_util_1.embedDocument)(text);
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
        }
        catch (err) {
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
//# sourceMappingURL=embed-listings.js.map
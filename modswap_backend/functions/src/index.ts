import express from 'express';
import cors from 'cors';
import { onRequest } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';

// Initialize Firebase Admin once
initializeApp();

import { createAuthRouter } from './modules/auth/auth.routes';
import listingsRoutes from './modules/listings/listings.routes';
import { errorHandlerMiddleware } from './middleware/error-handler.middleware';

// Re-export triggers
export { onUserCreate } from './triggers/auth/on-user-create.trigger';
export { onListingRemoved } from './triggers/listings/on-listing-delete.trigger';

// Express app
const app = express();

app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

// Health check
app.get('/health', (_, res) => {
  res.json({ ok: true, ts: new Date().toISOString() });
});

// Mount routes
// 🎯 แก้ตรงนี้ครับ เติมวงเล็บ ()
app.use('/auth', createAuthRouter());
app.use('/listings', listingsRoutes);

// Error handler (must be last)
app.use(errorHandlerMiddleware);

// Export the API
export const api = onRequest(
  {
    region: 'asia-southeast1',
    memory: '512MiB',
    timeoutSeconds: 60,
    cors: true,
  },
  app,
);
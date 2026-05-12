import express from 'express';
import cors from 'cors';
import { createAuthRouter } from './modules/auth/auth.routes';
import listingsRouter from './modules/listings/listings.routes';
import { errorHandlerMiddleware } from './middleware/error-handler.middleware';

/**
 * สร้าง Express app และ mount routes ทั้งหมด
 */
export function createApp(): express.Application {
  const app = express();

  // === Middleware ระดับโลก ===
  app.use(cors({ origin: true })); // อนุญาต Flutter เรียกข้าม origin
  app.use(express.json({ limit: '1mb' }));

  // === Health check ===
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  // === Routes ===
  app.use('/auth', createAuthRouter());
  app.use('/listings', listingsRouter);

  // === Error handler (ต้องอยู่ "ท้ายสุด") ===
  app.use(errorHandlerMiddleware);

  return app;
}

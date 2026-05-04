import { Request, Response, NextFunction } from 'express';
import { AppError } from '../core/errors/app-error';
import { errorResponse } from '../utils/response.util';
import { logger } from '../utils/logger.util';

/**
 * Error Handler Middleware (ต้องอยู่ "ท้ายสุด" ของ middleware chain)
 * จับ error ทุกตัวที่ next(error) มา แล้วส่ง response กลับ
 */
export function errorHandlerMiddleware(
  err: Error,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction
): void {
  // Custom AppError → ใช้ status + code ที่กำหนด
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error('AppError 5xx', err, { path: req.path });
    } else {
      logger.warn(`AppError ${err.statusCode}`, { code: err.code, message: err.message });
    }
    res.status(err.statusCode).json(errorResponse(err.code, err.message));
    return;
  }

  // Unknown error → 500
  logger.error('Unhandled error', err, { path: req.path });
  res.status(500).json(errorResponse('INTERNAL_ERROR', 'Something went wrong'));
}

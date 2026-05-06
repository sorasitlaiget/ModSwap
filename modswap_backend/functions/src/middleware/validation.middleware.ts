import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { BadRequestError } from '../core/errors/app-error';

/**
 * Helper: format Zod errors into a single readable message
 */
function formatZodError(error: ZodError): string {
  return error.errors
    .map((e) => `${e.path.join('.')}: ${e.message}`)
    .join(', ');
}

/**
 * Validation middleware for req.body
 * ใช้ Zod schema ตรวจ req.body แล้ว throw error ถ้าไม่ผ่าน
 */
export function validateBody<T>(schema: ZodSchema<T>) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        next(new BadRequestError(formatZodError(error), 'VALIDATION_ERROR'));
        return;
      }
      next(error);
    }
  };
}

/**
 * Validation middleware for req.query
 * ใช้สำหรับ GET endpoints ที่มี query params
 *
 * Note: req.query is read-only in newer Express, so we mutate properties
 *       individually instead of replacing the whole object.
 */
export function validateQuery<T extends Record<string, any>>(
  schema: ZodSchema<T>,
) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      const parsed = schema.parse(req.query);
      // Express 5: req.query is a getter, can't reassign
      // So we copy parsed values back
      Object.keys(parsed).forEach((key) => {
        (req.query as any)[key] = (parsed as any)[key];
      });
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        next(new BadRequestError(formatZodError(error), 'VALIDATION_ERROR'));
        return;
      }
      next(error);
    }
  };
}

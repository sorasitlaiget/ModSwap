import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { BadRequestError } from '../core/errors/app-error';

/**
 * Validation middleware
 * ใช้ Zod schema ตรวจ req.body แล้ว throw error ถ้าไม่ผ่าน
 */
export function validateBody<T>(schema: ZodSchema<T>) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const message = error.errors
          .map((e) => `${e.path.join('.')}: ${e.message}`)
          .join(', ');
        next(new BadRequestError(message, 'VALIDATION_ERROR'));
        return;
      }
      next(error);
    }
  };
}

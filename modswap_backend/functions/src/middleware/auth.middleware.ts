import { Request, Response, NextFunction } from 'express';
import { auth } from '../config/firebase.config';
import { KMUTT_EMAIL_DOMAIN } from '../config/constants';
import { UnauthorizedError, ForbiddenError } from '../core/errors/app-error';

/**
 * Extend Express Request เพื่อเพิ่ม req.user
 */
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: {
        uid: string;
        email: string;
        emailVerified: boolean;
      };
    }
  }
}

/**
 * Auth Middleware: ตรวจ Firebase ID Token + email domain ของ KMUTT
 * ใช้ใน routes ที่ต้อง login
 */
export async function authMiddleware(
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('Missing or invalid Authorization header');
    }

    const token = authHeader.substring(7);

    // Verify token กับ Firebase
    const decoded = await auth.verifyIdToken(token);

    // ตรวจ email domain
    if (!decoded.email || !decoded.email.endsWith(KMUTT_EMAIL_DOMAIN)) {
      throw new ForbiddenError(
        'Access denied. KMUTT email required.',
        'NOT_KMUTT_EMAIL'
      );
    }

    // แนบ user info ลงใน request
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      emailVerified: decoded.email_verified ?? false,
    };

    next();
  } catch (error) {
    // ถ้า error มาจาก Firebase verifyIdToken แปลงเป็น UnauthorizedError
    if (error instanceof Error && error.message.includes('Firebase ID token')) {
      next(new UnauthorizedError('Invalid or expired token'));
      return;
    }
    next(error);
  }
}

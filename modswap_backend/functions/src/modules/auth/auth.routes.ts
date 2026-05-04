import { Router } from 'express';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { UsersRepository } from '../users/users.repository';
import { authMiddleware } from '../../middleware/auth.middleware';
import { validateBody } from '../../middleware/validation.middleware';
import { completeProfileSchema, updateProfileSchema } from './auth.validator';

/**
 * Auth Routes
 * ประกอบ dependencies และผูก URL กับ controller
 */
export function createAuthRouter(): Router {
  const router = Router();

  // Composition Root: สร้าง dependency tree
  const usersRepo = new UsersRepository();
  const service = new AuthService(usersRepo);
  const controller = new AuthController(service);

  // ทุก route ต้อง login + เป็น KMUTT (ผ่าน authMiddleware)
  router.get('/me', authMiddleware, controller.getMyProfile);

  router.post(
    '/complete-profile',
    authMiddleware,
    validateBody(completeProfileSchema),
    controller.completeProfile
  );

  router.patch(
    '/profile',
    authMiddleware,
    validateBody(updateProfileSchema),
    controller.updateProfile
  );

  return router;
}

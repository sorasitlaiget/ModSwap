import { Request, Response, NextFunction } from 'express';
import { AuthService } from './auth.service';
import { successResponse } from '../../utils/response.util';

/**
 * Auth Controller - HTTP layer
 * รับ request → เรียก service → ส่ง response
 */
export class AuthController {
  constructor(private readonly service: AuthService) {}

  /**
   * GET /auth/me
   * ดึง profile ของตัวเอง
   */
  getMyProfile = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { uid, email } = req.user!;
      const profile = await this.service.getMyProfile(uid, email);
      res.json(successResponse(profile));
    } catch (error) {
      next(error);
    }
  };

  /**
   * POST /auth/complete-profile
   * เติมข้อมูล profile หลัง register
   */
  completeProfile = async (req: Request, res: Response, next: NextFunction) => {
    try {
      console.log('👉 [ด่าน 3] ผ่าน Middleware เข้ามาถึง Controller แล้ว!');
      const { uid, email } = req.user!;
      
      const profile = await this.service.completeProfile(uid, email, req.body);
      
      console.log('👉 [ด่านสุดท้าย] Service ทำงานเสร็จ จะส่ง Response แล้ว!');
      res.status(201).json(successResponse(profile));
    } catch (error) {
      console.error('❌ เกิด Error ใน Controller:', error);
      next(error);
    }
  };

  /**
   * PATCH /auth/profile
   * แก้ไข profile
   */
  updateProfile = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { uid, email } = req.user!;
      const profile = await this.service.updateProfile(uid, email, req.body);
      res.json(successResponse(profile));
    } catch (error) {
      next(error);
    }
  };

  /**
   * PATCH /auth/password
   * เปลี่ยน password
   */
  changePassword = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { uid } = req.user!;
      await this.service.changePassword(uid, req.body);
      res.json(successResponse({ message: 'Password changed successfully' }));
    } catch (error) {
      next(error);
    }
  };

  verifyDevice = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { uid } = req.user!;
      const { deviceId } = req.body as { deviceId: string };
      const result = await this.service.verifyDevice(uid, deviceId);
      res.json(successResponse(result));
    } catch (error) {
      next(error);
    }
  };
}

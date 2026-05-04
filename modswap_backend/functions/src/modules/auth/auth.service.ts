import { UsersRepository } from '../users/users.repository';
import { User } from '../users/users.types';
import {
  CompleteProfileDto,
  UpdateProfileDto,
  UserProfileResponseDto,
} from './dto/auth.dto';
import { NotFoundError, ConflictError } from '../../core/errors/app-error';
import { logger } from '../../utils/logger.util';

/**
 * Auth Service - business logic สำหรับ profile management
 *
 * หมายเหตุ: ตัว Login/Register จริง Frontend เรียก Firebase Auth SDK เอง
 * Service นี้จัดการเฉพาะ profile ที่อยู่ใน Firestore
 */
export class AuthService {
  constructor(private readonly usersRepo: UsersRepository) {}

  /**
   * ดึงข้อมูล profile ของตัวเอง
   * เรียกตอน app เปิดมาครั้งแรกเพื่อเช็คว่ากรอกข้อมูลครบหรือยัง
   */
  async getMyProfile(uid: string, email: string): Promise<UserProfileResponseDto> {
    const user = await this.usersRepo.findById(uid);

    if (!user) {
      // กรณีหายากที่ trigger ยังไม่ทำงาน - throw ให้ frontend retry
      throw new NotFoundError(
        'User profile not found. Please try again.',
        'PROFILE_NOT_FOUND'
      );
    }

    return this.toDto(user, email);
  }

  /**
   * เติมข้อมูล profile ครั้งแรก (หลัง register สำเร็จ)
   * Frontend ต้องเรียก endpoint นี้หลัง createUserWithEmailAndPassword
   */
  async completeProfile(
    uid: string,
    email: string,
    dto: CompleteProfileDto
  ): Promise<UserProfileResponseDto> {
    const user = await this.usersRepo.findById(uid);
    if (!user) {
      throw new NotFoundError('User profile not found');
    }

    // ป้องกันการเรียก complete ซ้ำ
    if (user.studentId && user.lineId) {
      throw new ConflictError(
        'Profile already completed. Use update endpoint instead.',
        'PROFILE_ALREADY_COMPLETED'
      );
    }

    await this.usersRepo.update(uid, {
      displayName: dto.displayName,
      studentId: dto.studentId,
      faculty: dto.faculty,
      lineId: dto.lineId,
    });

    logger.info('Profile completed', { uid });

    const updated = await this.usersRepo.findById(uid);
    return this.toDto(updated!, email);
  }

  /**
   * แก้ไข profile (หลังจาก complete แล้ว)
   */
  async updateProfile(
    uid: string,
    email: string,
    dto: UpdateProfileDto
  ): Promise<UserProfileResponseDto> {
    const user = await this.usersRepo.findById(uid);
    if (!user) {
      throw new NotFoundError('User profile not found');
    }

    await this.usersRepo.update(uid, dto);
    logger.info('Profile updated', { uid });

    const updated = await this.usersRepo.findById(uid);
    return this.toDto(updated!, email);
  }

  /**
   * แปลง Domain Model → Response DTO
   */
  private toDto(user: User, email: string): UserProfileResponseDto {
    const isProfileComplete = !!(user.studentId && user.lineId && user.faculty);

    return {
      id: user.id,
      email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      lineId: user.lineId,
      studentId: user.studentId,
      faculty: user.faculty,
      rating: user.rating,
      totalReviews: user.totalReviews,
      totalTrades: user.totalTrades,
      isProfileComplete,
      createdAt: user.createdAt.toDate().toISOString(),
      updatedAt: user.updatedAt.toDate().toISOString(),
    };
  }
}

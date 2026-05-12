import { UsersRepository } from '../users/users.repository';
import { User, UpdateUserProfileData } from '../users/users.types';
import {
  CompleteProfileDto,
  UpdateProfileDto,
  ChangePasswordDto,
  UserProfileResponseDto,
} from './dto/auth.dto';
import { NotFoundError, ConflictError } from '../../core/errors/app-error';
import { logger } from '../../utils/logger.util';
import { auth } from '../../config/firebase.config';

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
    console.log('👉 [ด่าน 4] เข้ามาใน Service กำลังจะหา User จาก Firestore...');
    const user = await this.usersRepo.findById(uid);
    console.log('👉 [ด่าน 5] หา User จาก Firestore เสร็จแล้ว!');
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
    
    console.log('👉 [ด่าน 6] กำลังจะ Update ลง Firestore...');
    const updated = await this.usersRepo.findById(uid);
    console.log('👉 [ด่าน 7] Update ลง Firestore เสร็จสมบูรณ์!');
    return this.toDto(updated!, email);
  }

  /**
   * แก้ไข profile (หลังจาก complete แล้ว)
   * - เช็คเฉพาะ field ที่เปลี่ยนจริง
   * - ตรวจ studentId ซ้ำกับ user อื่น
   */
  async updateProfile(
    uid: string,
    email: string,
    dto: UpdateProfileDto
  ): Promise<UserProfileResponseDto> {
    const current = await this.usersRepo.findById(uid);
    if (!current) {
      throw new NotFoundError('User profile not found');
    }

    // เอาเฉพาะ field ที่ส่งมาและมีค่าต่างจากปัจจุบัน
    const changes = this.detectChanges(current, dto);
    if (!changes) {
      return this.toDto(current, email);
    }

    // ตรวจ studentId ซ้ำกับ user อื่น
    if (changes.studentId) {
      const conflict = await this.usersRepo.findByStudentId(changes.studentId, uid);
      if (conflict) {
        throw new ConflictError('Student ID is already in use', 'STUDENT_ID_CONFLICT');
      }
    }

    await this.usersRepo.update(uid, changes);
    logger.info('Profile updated', { uid, fields: Object.keys(changes) });

    const updated = await this.usersRepo.findById(uid);
    return this.toDto(updated!, email);
  }

  /**
   * เปลี่ยน password ผ่าน Firebase Auth Admin SDK
   */
  async changePassword(uid: string, dto: ChangePasswordDto): Promise<void> {
    await auth.updateUser(uid, { password: dto.newPassword });
    logger.info('Password changed', { uid });
  }

  /**
   * เปรียบเทียบ dto กับข้อมูลปัจจุบัน → return เฉพาะ field ที่เปลี่ยน
   * ถ้าไม่มีอะไรเปลี่ยนเลย → return null
   */
  private detectChanges(current: User, dto: UpdateProfileDto): UpdateUserProfileData | null {
    const changes: UpdateUserProfileData = {};

    if (dto.displayName !== undefined && dto.displayName !== current.displayName) {
      changes.displayName = dto.displayName;
    }
    if (dto.studentId !== undefined && dto.studentId !== current.studentId) {
      changes.studentId = dto.studentId;
    }
    if (dto.faculty !== undefined && dto.faculty !== current.faculty) {
      changes.faculty = dto.faculty;
    }
    if (dto.lineId !== undefined && dto.lineId !== current.lineId) {
      changes.lineId = dto.lineId;
    }
    if (dto.photoURL !== undefined && dto.photoURL !== current.photoURL) {
      changes.photoURL = dto.photoURL ?? null;
    }

    return Object.keys(changes).length > 0 ? changes : null;
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

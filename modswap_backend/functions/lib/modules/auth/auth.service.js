"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const app_error_1 = require("../../core/errors/app-error");
const logger_util_1 = require("../../utils/logger.util");
/**
 * Auth Service - business logic สำหรับ profile management
 *
 * หมายเหตุ: ตัว Login/Register จริง Frontend เรียก Firebase Auth SDK เอง
 * Service นี้จัดการเฉพาะ profile ที่อยู่ใน Firestore
 */
class AuthService {
    constructor(usersRepo) {
        this.usersRepo = usersRepo;
    }
    /**
     * ดึงข้อมูล profile ของตัวเอง
     * เรียกตอน app เปิดมาครั้งแรกเพื่อเช็คว่ากรอกข้อมูลครบหรือยัง
     */
    async getMyProfile(uid, email) {
        const user = await this.usersRepo.findById(uid);
        if (!user) {
            // กรณีหายากที่ trigger ยังไม่ทำงาน - throw ให้ frontend retry
            throw new app_error_1.NotFoundError('User profile not found. Please try again.', 'PROFILE_NOT_FOUND');
        }
        return this.toDto(user, email);
    }
    /**
     * เติมข้อมูล profile ครั้งแรก (หลัง register สำเร็จ)
     * Frontend ต้องเรียก endpoint นี้หลัง createUserWithEmailAndPassword
     */
    async completeProfile(uid, email, dto) {
        console.log('👉 [ด่าน 4] เข้ามาใน Service กำลังจะหา User จาก Firestore...');
        const user = await this.usersRepo.findById(uid);
        console.log('👉 [ด่าน 5] หา User จาก Firestore เสร็จแล้ว!');
        if (!user) {
            throw new app_error_1.NotFoundError('User profile not found');
        }
        // ป้องกันการเรียก complete ซ้ำ
        if (user.studentId && user.lineId) {
            throw new app_error_1.ConflictError('Profile already completed. Use update endpoint instead.', 'PROFILE_ALREADY_COMPLETED');
        }
        await this.usersRepo.update(uid, {
            displayName: dto.displayName,
            studentId: dto.studentId,
            faculty: dto.faculty,
            lineId: dto.lineId,
        });
        logger_util_1.logger.info('Profile completed', { uid });
        console.log('👉 [ด่าน 6] กำลังจะ Update ลง Firestore...');
        const updated = await this.usersRepo.findById(uid);
        console.log('👉 [ด่าน 7] Update ลง Firestore เสร็จสมบูรณ์!');
        return this.toDto(updated, email);
    }
    /**
     * แก้ไข profile (หลังจาก complete แล้ว)
     */
    async updateProfile(uid, email, dto) {
        const user = await this.usersRepo.findById(uid);
        if (!user) {
            throw new app_error_1.NotFoundError('User profile not found');
        }
        await this.usersRepo.update(uid, dto);
        logger_util_1.logger.info('Profile updated', { uid });
        const updated = await this.usersRepo.findById(uid);
        return this.toDto(updated, email);
    }
    /**
     * แปลง Domain Model → Response DTO
     */
    toDto(user, email) {
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
exports.AuthService = AuthService;
//# sourceMappingURL=auth.service.js.map
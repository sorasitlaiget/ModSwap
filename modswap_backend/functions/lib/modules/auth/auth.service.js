"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const app_error_1 = require("../../core/errors/app-error");
const logger_util_1 = require("../../utils/logger.util");
const firebase_config_1 = require("../../config/firebase.config");
const notification_util_1 = require("../../utils/notification.util");
const constants_1 = require("../../config/constants");
const firestore_1 = require("firebase-admin/firestore");
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
     * - เช็คเฉพาะ field ที่เปลี่ยนจริง
     * - ตรวจ studentId ซ้ำกับ user อื่น
     */
    async updateProfile(uid, email, dto) {
        const current = await this.usersRepo.findById(uid);
        if (!current) {
            throw new app_error_1.NotFoundError('User profile not found');
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
                throw new app_error_1.ConflictError('Student ID is already in use', 'STUDENT_ID_CONFLICT');
            }
        }
        await this.usersRepo.update(uid, changes);
        logger_util_1.logger.info('Profile updated', { uid, fields: Object.keys(changes) });
        const updated = await this.usersRepo.findById(uid);
        return this.toDto(updated, email);
    }
    /**
     * เปลี่ยน password ผ่าน Firebase Auth Admin SDK
     */
    async changePassword(uid, dto) {
        await firebase_config_1.auth.updateUser(uid, { password: dto.newPassword });
        logger_util_1.logger.info('Password changed', { uid });
        // Fire-and-forget: notify user
        const now = new Date();
        const timeStr = now.toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit' });
        (0, notification_util_1.sendNotification)({
            recipientUid: uid,
            type: 'passwordChanged',
            title: 'Password Changed',
            body: `Your password was changed at ${timeStr}`,
        }).catch(() => null);
    }
    async verifyDevice(uid, deviceId) {
        const deviceRef = firebase_config_1.db
            .collection(constants_1.COLLECTIONS.USERS)
            .doc(uid)
            .collection(constants_1.SUBCOLLECTIONS.DEVICES)
            .doc(deviceId);
        const snap = await deviceRef.get();
        if (snap.exists)
            return { isNewDevice: false };
        // New device — save it and notify user
        await Promise.all([
            deviceRef.set({ addedAt: firestore_1.Timestamp.now() }),
            (0, notification_util_1.sendNotification)({
                recipientUid: uid,
                type: 'securityAlert',
                title: 'New Login Detected',
                body: 'Login from a new device. If this wasn\'t you, secure your account.',
                deepLinkTarget: '/security',
            }),
        ]);
        logger_util_1.logger.info('New device registered', { uid, deviceId });
        return { isNewDevice: true };
    }
    /**
     * เปรียบเทียบ dto กับข้อมูลปัจจุบัน → return เฉพาะ field ที่เปลี่ยน
     * ถ้าไม่มีอะไรเปลี่ยนเลย → return null
     */
    detectChanges(current, dto) {
        const changes = {};
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
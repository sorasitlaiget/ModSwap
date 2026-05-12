"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserDelete = exports.onUserCreate = void 0;
const functionsV1 = __importStar(require("firebase-functions/v1"));
const firebase_config_1 = require("../../config/firebase.config");
const constants_1 = require("../../config/constants");
const logger_util_1 = require("../../utils/logger.util");
const firestore_1 = require("firebase-admin/firestore");
/**
 * Auth Trigger: ทำงานทันทีที่มีคน register สำเร็จ
 *
 * ⭐ นี่คือ "ด่านหลัก" ที่ป้องกันคนนอก KMUTT
 * เพราะคนสามารถเรียก Firebase Auth SDK ตรงข้าม Frontend ของเราได้
 *
 * Flow:
 * 1. ตรวจ email domain → ถ้าไม่ใช่ KMUTT ลบ user ทิ้งทันที
 * 2. สร้าง user profile ใน Firestore
 * 3. ตั้ง custom claims (role)
 */
exports.onUserCreate = functionsV1
    .region('asia-southeast1')
    .auth.user()
    .onCreate(async (user) => {
    const { uid, email, displayName, photoURL } = user;
    logger_util_1.logger.info('New user signup', { uid, email });
    // === Step 1: ตรวจ KMUTT email ===
    if (!email || !email.endsWith(constants_1.KMUTT_EMAIL_DOMAIN)) {
        logger_util_1.logger.warn('Non-KMUTT user attempted signup, deleting', { uid, email });
        try {
            await firebase_config_1.auth.deleteUser(uid);
            logger_util_1.logger.info('Non-KMUTT user deleted', { uid });
        }
        catch (err) {
            logger_util_1.logger.error('Failed to delete non-KMUTT user', err, { uid });
        }
        return;
    }
    // === Step 2: สร้าง user profile ใน Firestore ===
    try {
        const now = firestore_1.Timestamp.now();
        await firebase_config_1.firestore
            .collection(constants_1.COLLECTIONS.USERS)
            .doc(uid)
            .set({
            id: uid,
            email,
            displayName: displayName ?? email.split('@')[0],
            photoURL: photoURL ?? null,
            lineId: null,
            studentId: null,
            faculty: null,
            rating: 0,
            totalReviews: 0,
            totalTrades: 0,
            createdAt: now,
            updatedAt: now,
        });
        // === Step 3: ตั้ง custom claims ===
        await firebase_config_1.auth.setCustomUserClaims(uid, {
            role: constants_1.USER_ROLES.STUDENT,
            kmutt: true,
        });
        logger_util_1.logger.info('User profile created successfully', { uid, email });
    }
    catch (err) {
        logger_util_1.logger.error('Failed to create user profile', err, { uid });
        // ถ้าสร้าง profile ไม่ได้ ลบ Auth user ทิ้งเพื่อให้ retry ได้
        try {
            await firebase_config_1.auth.deleteUser(uid);
        }
        catch (deleteErr) {
            logger_util_1.logger.error('Failed to cleanup auth user', deleteErr, { uid });
        }
    }
});
/**
 * Auth Trigger: ทำงานเมื่อ user ถูกลบ
 * ลบ profile ใน Firestore ตาม
 */
exports.onUserDelete = functionsV1
    .region('asia-southeast1')
    .auth.user()
    .onDelete(async (user) => {
    const { uid } = user;
    try {
        await firebase_config_1.firestore.collection(constants_1.COLLECTIONS.USERS).doc(uid).delete();
        logger_util_1.logger.info('User profile deleted', { uid });
    }
    catch (err) {
        logger_util_1.logger.error('Failed to delete user profile', err, { uid });
    }
});
//# sourceMappingURL=on-user-create.trigger.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
const firebase_config_1 = require("../config/firebase.config");
const constants_1 = require("../config/constants");
const app_error_1 = require("../core/errors/app-error");
/**
 * Auth Middleware: ตรวจ Firebase ID Token + email domain ของ KMUTT
 * ใช้ใน routes ที่ต้อง login
 */
async function authMiddleware(req, _res, next) {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            throw new app_error_1.UnauthorizedError('Missing or invalid Authorization header');
        }
        const token = authHeader.substring(7);
        // Verify token กับ Firebase
        const decoded = await firebase_config_1.auth.verifyIdToken(token);
        // ตรวจ email domain
        if (!decoded.email || !decoded.email.endsWith(constants_1.KMUTT_EMAIL_DOMAIN)) {
            throw new app_error_1.ForbiddenError('Access denied. KMUTT email required.', 'NOT_KMUTT_EMAIL');
        }
        // แนบ user info ลงใน request
        req.user = {
            uid: decoded.uid,
            email: decoded.email,
            emailVerified: decoded.email_verified ?? false,
        };
        next();
    }
    catch (error) {
        // ถ้า error มาจาก Firebase verifyIdToken แปลงเป็น UnauthorizedError
        if (error instanceof Error && error.message.includes('Firebase ID token')) {
            next(new app_error_1.UnauthorizedError('Invalid or expired token'));
            return;
        }
        next(error);
    }
}
//# sourceMappingURL=auth.middleware.js.map
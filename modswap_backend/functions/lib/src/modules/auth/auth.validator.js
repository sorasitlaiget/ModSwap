"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateProfileSchema = exports.completeProfileSchema = exports.passwordSchema = void 0;
const zod_1 = require("zod");
/**
 * Validation schemas สำหรับ auth endpoints
 */
exports.passwordSchema = zod_1.z.string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter');
exports.completeProfileSchema = zod_1.z.object({
    displayName: zod_1.z
        .string()
        .min(1, 'Please enter your name')
        .max(50, 'Your name is too long')
        .trim(),
    studentId: zod_1.z
        .string()
        .regex(/^\d{11}$/, 'StudenId must be 11 digit'),
    faculty: zod_1.z
        .string()
        .min(1, 'Please select your faculty')
        .max(100)
        .trim(),
    lineId: zod_1.z
        .string()
        .min(1, 'Please enter your LineID')
        .max(50)
        .trim(),
});
exports.updateProfileSchema = zod_1.z.object({
    displayName: zod_1.z.string().min(1).max(50).trim().optional(),
    studentId: zod_1.z.string().regex(/^\d{11}$/).optional(),
    faculty: zod_1.z.string().min(1).max(100).trim().optional(),
    lineId: zod_1.z.string().min(1).max(50).trim().optional(),
    photoURL: zod_1.z.string().url().optional(),
});
//# sourceMappingURL=auth.validator.js.map
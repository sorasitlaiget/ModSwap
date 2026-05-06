"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateBody = validateBody;
exports.validateQuery = validateQuery;
const zod_1 = require("zod");
const app_error_1 = require("../core/errors/app-error");
/**
 * Helper: format Zod errors into a single readable message
 */
function formatZodError(error) {
    return error.errors
        .map((e) => `${e.path.join('.')}: ${e.message}`)
        .join(', ');
}
/**
 * Validation middleware for req.body
 * ใช้ Zod schema ตรวจ req.body แล้ว throw error ถ้าไม่ผ่าน
 */
function validateBody(schema) {
    return (req, _res, next) => {
        try {
            req.body = schema.parse(req.body);
            next();
        }
        catch (error) {
            if (error instanceof zod_1.ZodError) {
                next(new app_error_1.BadRequestError(formatZodError(error), 'VALIDATION_ERROR'));
                return;
            }
            next(error);
        }
    };
}
/**
 * Validation middleware for req.query
 * ใช้สำหรับ GET endpoints ที่มี query params
 *
 * Note: req.query is read-only in newer Express, so we mutate properties
 *       individually instead of replacing the whole object.
 */
function validateQuery(schema) {
    return (req, _res, next) => {
        try {
            const parsed = schema.parse(req.query);
            // Express 5: req.query is a getter, can't reassign
            // So we copy parsed values back
            Object.keys(parsed).forEach((key) => {
                req.query[key] = parsed[key];
            });
            next();
        }
        catch (error) {
            if (error instanceof zod_1.ZodError) {
                next(new app_error_1.BadRequestError(formatZodError(error), 'VALIDATION_ERROR'));
                return;
            }
            next(error);
        }
    };
}
//# sourceMappingURL=validation.middleware.js.map
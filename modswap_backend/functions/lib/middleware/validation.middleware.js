"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateBody = validateBody;
const zod_1 = require("zod");
const app_error_1 = require("../core/errors/app-error");
/**
 * Validation middleware
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
                const message = error.errors
                    .map((e) => `${e.path.join('.')}: ${e.message}`)
                    .join(', ');
                next(new app_error_1.BadRequestError(message, 'VALIDATION_ERROR'));
                return;
            }
            next(error);
        }
    };
}
//# sourceMappingURL=validation.middleware.js.map
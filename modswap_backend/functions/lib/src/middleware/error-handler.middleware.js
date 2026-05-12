"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorHandlerMiddleware = errorHandlerMiddleware;
const app_error_1 = require("../core/errors/app-error");
const response_util_1 = require("../utils/response.util");
const logger_util_1 = require("../utils/logger.util");
/**
 * Error Handler Middleware (ต้องอยู่ "ท้ายสุด" ของ middleware chain)
 * จับ error ทุกตัวที่ next(error) มา แล้วส่ง response กลับ
 */
function errorHandlerMiddleware(err, req, res, 
// eslint-disable-next-line @typescript-eslint/no-unused-vars
_next) {
    // Custom AppError → ใช้ status + code ที่กำหนด
    if (err instanceof app_error_1.AppError) {
        if (err.statusCode >= 500) {
            logger_util_1.logger.error('AppError 5xx', err, { path: req.path });
        }
        else {
            logger_util_1.logger.warn(`AppError ${err.statusCode}`, { code: err.code, message: err.message });
        }
        res.status(err.statusCode).json((0, response_util_1.errorResponse)(err.code, err.message));
        return;
    }
    // Unknown error → 500
    logger_util_1.logger.error('Unhandled error', err, { path: req.path });
    res.status(500).json((0, response_util_1.errorResponse)('INTERNAL_ERROR', 'Something went wrong'));
}
//# sourceMappingURL=error-handler.middleware.js.map
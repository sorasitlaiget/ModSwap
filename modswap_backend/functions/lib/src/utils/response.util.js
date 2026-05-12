"use strict";
/**
 * Helpers สำหรับ format API response ให้เป็นมาตรฐาน
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.successResponse = successResponse;
exports.errorResponse = errorResponse;
function successResponse(data) {
    return { success: true, data };
}
function errorResponse(code, message) {
    return { success: false, error: { code, message } };
}
//# sourceMappingURL=response.util.js.map
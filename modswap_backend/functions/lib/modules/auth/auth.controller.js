"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const response_util_1 = require("../../utils/response.util");
/**
 * Auth Controller - HTTP layer
 * รับ request → เรียก service → ส่ง response
 */
class AuthController {
    constructor(service) {
        this.service = service;
        /**
         * GET /auth/me
         * ดึง profile ของตัวเอง
         */
        this.getMyProfile = async (req, res, next) => {
            try {
                const { uid, email } = req.user;
                const profile = await this.service.getMyProfile(uid, email);
                res.json((0, response_util_1.successResponse)(profile));
            }
            catch (error) {
                next(error);
            }
        };
        /**
         * POST /auth/complete-profile
         * เติมข้อมูล profile หลัง register
         */
        this.completeProfile = async (req, res, next) => {
            try {
                const { uid, email } = req.user;
                const profile = await this.service.completeProfile(uid, email, req.body);
                res.status(201).json((0, response_util_1.successResponse)(profile));
            }
            catch (error) {
                next(error);
            }
        };
        /**
         * PATCH /auth/profile
         * แก้ไข profile
         */
        this.updateProfile = async (req, res, next) => {
            try {
                const { uid, email } = req.user;
                const profile = await this.service.updateProfile(uid, email, req.body);
                res.json((0, response_util_1.successResponse)(profile));
            }
            catch (error) {
                next(error);
            }
        };
    }
}
exports.AuthController = AuthController;
//# sourceMappingURL=auth.controller.js.map
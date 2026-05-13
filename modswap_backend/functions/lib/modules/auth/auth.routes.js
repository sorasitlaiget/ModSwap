"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createAuthRouter = createAuthRouter;
const express_1 = require("express");
const auth_controller_1 = require("./auth.controller");
const auth_service_1 = require("./auth.service");
const users_repository_1 = require("../users/users.repository");
const auth_middleware_1 = require("../../middleware/auth.middleware");
const validation_middleware_1 = require("../../middleware/validation.middleware");
const auth_validator_1 = require("./auth.validator");
/**
 * Auth Routes
 * ประกอบ dependencies และผูก URL กับ controller
 */
function createAuthRouter() {
    const router = (0, express_1.Router)();
    // Composition Root: สร้าง dependency tree
    const usersRepo = new users_repository_1.UsersRepository();
    const service = new auth_service_1.AuthService(usersRepo);
    const controller = new auth_controller_1.AuthController(service);
    // ทุก route ต้อง login + เป็น KMUTT (ผ่าน authMiddleware)
    router.get('/me', auth_middleware_1.authMiddleware, controller.getMyProfile);
    router.post('/complete-profile', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(auth_validator_1.completeProfileSchema), controller.completeProfile);
    router.patch('/profile', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(auth_validator_1.updateProfileSchema), controller.updateProfile);
    router.patch('/password', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(auth_validator_1.changePasswordSchema), controller.changePassword);
    router.post('/verify-device', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(auth_validator_1.verifyDeviceSchema), controller.verifyDevice);
    return router;
}
//# sourceMappingURL=auth.routes.js.map
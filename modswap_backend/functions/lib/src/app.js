"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createApp = createApp;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const auth_routes_1 = require("./modules/auth/auth.routes");
const error_handler_middleware_1 = require("./middleware/error-handler.middleware");
/**
 * สร้าง Express app และ mount routes ทั้งหมด
 */
function createApp() {
    const app = (0, express_1.default)();
    // === Middleware ระดับโลก ===
    app.use((0, cors_1.default)({ origin: true })); // อนุญาต Flutter เรียกข้าม origin
    app.use(express_1.default.json({ limit: '1mb' }));
    // === Health check ===
    app.get('/health', (_req, res) => {
        res.json({ status: 'ok', timestamp: new Date().toISOString() });
    });
    // === Routes ===
    app.use('/auth', (0, auth_routes_1.createAuthRouter)());
    // ✏️ ใส่ routes อื่นๆ ที่นี่ในอนาคต
    // app.use('/listings', createListingsRouter());
    // === Error handler (ต้องอยู่ "ท้ายสุด") ===
    app.use(error_handler_middleware_1.errorHandlerMiddleware);
    return app;
}
//# sourceMappingURL=app.js.map
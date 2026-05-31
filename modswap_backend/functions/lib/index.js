"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = exports.onListingRemoved = exports.onUserCreate = void 0;
require("dotenv/config");
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const https_1 = require("firebase-functions/v2/https");
const app_1 = require("firebase-admin/app");
// Initialize Firebase Admin once
(0, app_1.initializeApp)();
const auth_routes_1 = require("./modules/auth/auth.routes");
const listings_routes_1 = __importDefault(require("./modules/listings/listings.routes"));
const error_handler_middleware_1 = require("./middleware/error-handler.middleware");
const wishlist_routes_1 = __importDefault(require("./modules/wishlist/wishlist.routes"));
const ratings_routes_1 = require("./modules/ratings/ratings.routes");
// Re-export triggers
var on_user_create_trigger_1 = require("./triggers/auth/on-user-create.trigger");
Object.defineProperty(exports, "onUserCreate", { enumerable: true, get: function () { return on_user_create_trigger_1.onUserCreate; } });
var on_listing_delete_trigger_1 = require("./triggers/listings/on-listing-delete.trigger");
Object.defineProperty(exports, "onListingRemoved", { enumerable: true, get: function () { return on_listing_delete_trigger_1.onListingRemoved; } });
// Express app
const app = (0, express_1.default)();
app.use((0, cors_1.default)({ origin: true }));
app.use(express_1.default.json({ limit: '1mb' }));
// Health check
app.get('/health', (_, res) => {
    res.json({ ok: true, ts: new Date().toISOString() });
});
// Mount routes
// 🎯 แก้ตรงนี้ครับ เติมวงเล็บ ()
app.use('/auth', (0, auth_routes_1.createAuthRouter)());
app.use('/listings', listings_routes_1.default);
app.use('/wishlist', wishlist_routes_1.default);
app.use('/ratings', (0, ratings_routes_1.createRatingsRouter)());
// Error handler (must be last)
app.use(error_handler_middleware_1.errorHandlerMiddleware);
// Export the API
exports.api = (0, https_1.onRequest)({
    region: 'asia-southeast1',
    memory: '512MiB',
    timeoutSeconds: 60,
    cors: true,
}, app);
//# sourceMappingURL=index.js.map
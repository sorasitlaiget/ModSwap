"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WishlistController = void 0;
const app_error_1 = require("../../core/errors/app-error");
/**
 * Wishlist Controller - HTTP layer
 */
class WishlistController {
    constructor(service) {
        this.service = service;
        /**
         * POST /wishlist/:listingId — Add to wishlist
         */
        this.add = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                await this.service.add(uid, req.params.listingId);
                res.status(201).json({
                    success: true,
                    message: 'Added to wishlist',
                });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * DELETE /wishlist/:listingId — Remove from wishlist
         */
        this.remove = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                await this.service.remove(uid, req.params.listingId);
                res.json({
                    success: true,
                    message: 'Removed from wishlist',
                });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * GET /wishlist/check/:listingId — Check membership
         */
        this.check = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.check(uid, req.params.listingId);
                res.json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * GET /wishlist — List user's wishlist with full listing data
         */
        this.list = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.findAll(uid);
                res.json({ success: true, data, count: data.length });
            }
            catch (err) {
                next(err);
            }
        };
    }
}
exports.WishlistController = WishlistController;
//# sourceMappingURL=wishlist.controller.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middleware_1 = require("../../middleware/auth.middleware");
const listings_repository_1 = require("../listings/listings.repository");
const wishlist_controller_1 = require("./wishlist.controller");
const wishlist_repository_1 = require("./wishlist.repository");
const wishlist_service_1 = require("./wishlist.service");
const router = (0, express_1.Router)();
// Wire up dependencies (DI)
const wishlistRepo = new wishlist_repository_1.WishlistRepository();
const listingsRepo = new listings_repository_1.ListingsRepository();
const service = new wishlist_service_1.WishlistService(wishlistRepo, listingsRepo);
const controller = new wishlist_controller_1.WishlistController(service);
/**
 * Wishlist Routes (all require auth)
 *
 * GET    /                          List my wishlist (full listing data)
 * GET    /check/:listingId          Check if listing is in my wishlist
 * POST   /:listingId                Add to wishlist
 * DELETE /:listingId                Remove from wishlist
 */
router.get('/', auth_middleware_1.authMiddleware, controller.list);
router.get('/check/:listingId', auth_middleware_1.authMiddleware, controller.check);
router.post('/:listingId', auth_middleware_1.authMiddleware, controller.add);
router.delete('/:listingId', auth_middleware_1.authMiddleware, controller.remove);
exports.default = router;
//# sourceMappingURL=wishlist.routes.js.map
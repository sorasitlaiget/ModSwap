"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middleware_1 = require("../../middleware/auth.middleware");
const validation_middleware_1 = require("../../middleware/validation.middleware");
const users_repository_1 = require("../users/users.repository");
const listings_repository_1 = require("./listings.repository");
const listings_service_1 = require("./listings.service");
const listings_controller_1 = require("./listings.controller");
const listings_validator_1 = require("./listings.validator");
const deals_repository_1 = require("../deals/deals.repository");
const deals_service_1 = require("../deals/deals.service");
const deals_controller_1 = require("../deals/deals.controller");
const deals_validator_1 = require("../deals/deals.validator");
const router = (0, express_1.Router)();
// Wire up dependencies (DI)
const usersRepo = new users_repository_1.UsersRepository();
const listingsRepo = new listings_repository_1.ListingsRepository();
const listingsService = new listings_service_1.ListingsService(listingsRepo, usersRepo);
const controller = new listings_controller_1.ListingsController(listingsService);
const dealsRepo = new deals_repository_1.DealsRepository();
const dealsService = new deals_service_1.DealsService(dealsRepo, listingsRepo, usersRepo);
const dealsController = new deals_controller_1.DealsController(dealsService);
/**
 * Listings Routes
 *
 * GET    /                  Browse published
 * GET    /my                My listings (drafts + published + sold)
 * GET    /:id               View listing detail
 * POST   /                  Create draft
 * PATCH  /:id               Update fields
 * POST   /:id/publish       Publish a draft (convenience — same as PATCH /state with 'published')
 * POST   /:id/sold          Mark as sold (convenience — same as PATCH /state with 'sold')
 * PATCH  /:id/state         Change state freely { state: 'draft' | 'published' | 'sold' }
 * DELETE /:id               Soft delete
 */
router.get('/', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateQuery)(listings_validator_1.listingsQuerySchema), controller.list);
router.get('/my', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateQuery)(listings_validator_1.myListingsQuerySchema), controller.myListings);
router.get('/:id', auth_middleware_1.authMiddleware, controller.getById);
router.post('/', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(listings_validator_1.createDraftSchema), controller.create);
router.patch('/:id', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(listings_validator_1.updateListingSchema), controller.update);
// Convenience endpoints
router.post('/:id/publish', auth_middleware_1.authMiddleware, controller.publish);
// Mark as sold — creates a deal record and flips listing state to 'sold'
router.post('/:id/sold', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(deals_validator_1.markAsSoldSchema), dealsController.markAsSold);
// Get the deal record for a sold listing (owner only)
router.get('/:id/deal', auth_middleware_1.authMiddleware, dealsController.getDeal);
// Generic state change
router.patch('/:id/state', auth_middleware_1.authMiddleware, (0, validation_middleware_1.validateBody)(listings_validator_1.changeStateSchema), controller.changeState);
router.delete('/:id', auth_middleware_1.authMiddleware, controller.delete);
exports.default = router;
//# sourceMappingURL=listings.routes.js.map
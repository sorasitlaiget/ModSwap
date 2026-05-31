import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import {
  validateBody,
  validateQuery,
} from '../../middleware/validation.middleware';
import { UsersRepository } from '../users/users.repository';
import { ListingsRepository } from './listings.repository';
import { ListingsService } from './listings.service';
import { ListingsController } from './listings.controller';
import {
  changeStateSchema,
  createDraftSchema,
  listingsQuerySchema,
  myListingsQuerySchema,
  updateListingSchema,
} from './listings.validator';
import { DealsRepository } from '../deals/deals.repository';
import { DealsService } from '../deals/deals.service';
import { DealsController } from '../deals/deals.controller';
import { markAsSoldSchema } from '../deals/deals.validator';

const router = Router();

// Wire up dependencies (DI)
const usersRepo = new UsersRepository();
const listingsRepo = new ListingsRepository();
const listingsService = new ListingsService(listingsRepo, usersRepo);
const controller = new ListingsController(listingsService);

const dealsRepo = new DealsRepository();
const dealsService = new DealsService(dealsRepo, listingsRepo, usersRepo);
const dealsController = new DealsController(dealsService);

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

router.get(
  '/',
  authMiddleware,
  validateQuery(listingsQuerySchema),
  controller.list,
);

router.get(
  '/my',
  authMiddleware,
  validateQuery(myListingsQuerySchema),
  controller.myListings,
);

// ⭐ Smart semantic search (must come before /:id)
router.post('/search', authMiddleware, controller.search);

router.get('/:id', authMiddleware, controller.getById);

router.post(
  '/',
  authMiddleware,
  validateBody(createDraftSchema),
  controller.create,
);

router.patch(
  '/:id',
  authMiddleware,
  validateBody(updateListingSchema),
  controller.update,
);

// Convenience endpoints
router.post('/:id/publish', authMiddleware, controller.publish);

// Mark as sold — creates a deal record and flips listing state to 'sold'
router.post(
  '/:id/sold',
  authMiddleware,
  validateBody(markAsSoldSchema),
  dealsController.markAsSold,
);

// Get the deal record for a sold listing (owner only)
router.get('/:id/deal', authMiddleware, dealsController.getDeal);

// Generic state change
router.patch(
  '/:id/state',
  authMiddleware,
  validateBody(changeStateSchema),
  controller.changeState,
);

router.delete('/:id', authMiddleware, controller.delete);

export default router;

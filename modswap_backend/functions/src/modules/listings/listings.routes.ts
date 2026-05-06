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

const router = Router();

// Wire up dependencies (DI)
const usersRepo = new UsersRepository();
const listingsRepo = new ListingsRepository();
const listingsService = new ListingsService(listingsRepo, usersRepo);
const controller = new ListingsController(listingsService);

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
router.post('/:id/sold', authMiddleware, controller.markSold);

// Generic state change
router.patch(
  '/:id/state',
  authMiddleware,
  validateBody(changeStateSchema),
  controller.changeState,
);

router.delete('/:id', authMiddleware, controller.delete);

export default router;

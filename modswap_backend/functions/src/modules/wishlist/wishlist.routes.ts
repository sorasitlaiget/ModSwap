import { Router } from 'express';
import { authMiddleware } from '../../middleware/auth.middleware';
import { ListingsRepository } from '../listings/listings.repository';
import { WishlistController } from './wishlist.controller';
import { WishlistRepository } from './wishlist.repository';
import { WishlistService } from './wishlist.service';

const router = Router();

// Wire up dependencies (DI)
const wishlistRepo = new WishlistRepository();
const listingsRepo = new ListingsRepository();
const service = new WishlistService(wishlistRepo, listingsRepo);
const controller = new WishlistController(service);

/**
 * Wishlist Routes (all require auth)
 *
 * GET    /                          List my wishlist (full listing data)
 * GET    /check/:listingId          Check if listing is in my wishlist
 * POST   /:listingId                Add to wishlist
 * DELETE /:listingId                Remove from wishlist
 */

router.get('/', authMiddleware, controller.list);
router.get('/check/:listingId', authMiddleware, controller.check);
router.post('/:listingId', authMiddleware, controller.add);
router.delete('/:listingId', authMiddleware, controller.remove);

export default router;

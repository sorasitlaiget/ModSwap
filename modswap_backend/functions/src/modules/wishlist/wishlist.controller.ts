import type { Request, Response, NextFunction } from 'express';
import { UnauthorizedError } from '../../core/errors/app-error';
import { WishlistService } from './wishlist.service';

/**
 * Wishlist Controller - HTTP layer
 */
export class WishlistController {
  constructor(private readonly service: WishlistService) {}

  /**
   * POST /wishlist/:listingId — Add to wishlist
   */
  add = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      await this.service.add(uid, req.params.listingId);
      res.status(201).json({
        success: true,
        message: 'Added to wishlist',
      });
    } catch (err) {
      next(err);
    }
  };

  /**
   * DELETE /wishlist/:listingId — Remove from wishlist
   */
  remove = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      await this.service.remove(uid, req.params.listingId);
      res.json({
        success: true,
        message: 'Removed from wishlist',
      });
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /wishlist/check/:listingId — Check membership
   */
  check = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.check(uid, req.params.listingId);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /wishlist — List user's wishlist with full listing data
   */
  list = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.findAll(uid);
      res.json({ success: true, data, count: data.length });
    } catch (err) {
      next(err);
    }
  };
}

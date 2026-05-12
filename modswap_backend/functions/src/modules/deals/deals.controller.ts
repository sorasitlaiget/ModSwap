import type { Request, Response, NextFunction } from 'express';
import { DealsService } from './deals.service';
import { UnauthorizedError } from '../../core/errors/app-error';

/**
 * Deals Controller — HTTP layer for deal-related actions
 * Routes are mounted under /listings (param name: :id)
 */
export class DealsController {
  constructor(private readonly service: DealsService) {}

  /**
   * POST /listings/:id/sold
   * Body: MarkAsSoldDto (validated by markAsSoldSchema)
   */
  markAsSold = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.markAsSold(uid, req.params.id, req.body);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /listings/:id/deal
   * Returns the deal record for a sold listing (owner only)
   */
  getDeal = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.getDealByListingId(uid, req.params.id);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };
}

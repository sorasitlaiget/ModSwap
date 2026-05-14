import type { Request, Response, NextFunction } from 'express';
import { ListingsService } from './listings.service';
import { UnauthorizedError } from '../../core/errors/app-error';

/**
 * Listings Controller - HTTP layer
 */
export class ListingsController {
  constructor(private readonly service: ListingsService) {}

  /**
   * POST /listings - Create draft
   */
  create = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.createDraft(uid, req.body);
      res.status(201).json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  /**
   * PATCH /listings/:id - Update fields
   */
  update = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.update(uid, req.params.id, req.body);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /listings/:id/publish - Publish (legacy convenience endpoint)
   */
  publish = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.publish(uid, req.params.id);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /listings/:id/sold - Mark as sold (legacy convenience endpoint)
   */
  markSold = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.markSold(uid, req.params.id);
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  /**
   * PATCH /listings/:id/state - Change state freely
   * Body: { state: 'draft' | 'published' | 'sold' }
   */
  changeState = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.changeState(
        uid,
        req.params.id,
        req.body.state,
      );
      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  /**
   * DELETE /listings/:id - Soft delete
   */
  delete = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      await this.service.delete(uid, req.params.id);
      res.json({ success: true, message: 'Listing deleted' });
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /listings/:id - Detail
   */
  getById = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      const data = await this.service.getById(req.params.id, uid);

      if (uid) {
        this.service.recordView(req.params.id, uid).catch(() => null);
      }

      res.json({ success: true, data });
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /listings - Browse published
   */
  list = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const data = await this.service.findPublished(req.query as any);
      res.json({ success: true, data, count: data.length });
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /listings/my - My listings
   */
  myListings = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const uid = req.user?.uid;
      if (!uid) throw new UnauthorizedError();

      const data = await this.service.findMyListings(uid, req.query as any);
      res.json({ success: true, data, count: data.length });
    } catch (err) {
      next(err);
    }
  };

  /**
   * ⭐ POST /listings/search — Smart semantic search
   *
   * Body:
   *   {
   *     "query": "flower",
   *     "category": "others",   // optional filter
   *     "type": "sell",         // optional filter
   *     "limit": 20             // optional, default 20
   *   }
   */
  search = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { query, category, type, limit } = req.body as {
        query?: string;
        category?: string;
        type?: string;
        limit?: number;
      };

      if (!query || typeof query !== 'string' || query.trim().length === 0) {
        res.status(400).json({
          success: false,
          error: { message: 'Query is required' },
        });
        return;
      }

      const data = await this.service.search({
        query: query.trim(),
        category,
        type,
        limit,
      });

      res.json({
        success: true,
        data,
        count: data.length,
        query,
      });
    } catch (err) {
      next(err);
    }
  };
}

"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DealsController = void 0;
const app_error_1 = require("../../core/errors/app-error");
/**
 * Deals Controller — HTTP layer for deal-related actions
 * Routes are mounted under /listings (param name: :id)
 */
class DealsController {
    constructor(service) {
        this.service = service;
        /**
         * POST /listings/:id/sold
         * Body: MarkAsSoldDto (validated by markAsSoldSchema)
         */
        this.markAsSold = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.markAsSold(uid, req.params.id, req.body);
                res.json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * GET /listings/:id/deal
         * Returns the deal record for a sold listing (owner only)
         */
        this.getDeal = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.getDealByListingId(uid, req.params.id);
                res.json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
    }
}
exports.DealsController = DealsController;
//# sourceMappingURL=deals.controller.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ListingsController = void 0;
const app_error_1 = require("../../core/errors/app-error");
/**
 * Listings Controller - HTTP layer
 */
class ListingsController {
    constructor(service) {
        this.service = service;
        /**
         * POST /listings - Create draft
         */
        this.create = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.createDraft(uid, req.body);
                res.status(201).json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * PATCH /listings/:id - Update fields
         */
        this.update = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.update(uid, req.params.id, req.body);
                res.json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * POST /listings/:id/publish - Publish (legacy convenience endpoint)
         */
        this.publish = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.publish(uid, req.params.id);
                res.json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * POST /listings/:id/sold - Mark as sold (legacy convenience endpoint)
         */
        this.markSold = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.markSold(uid, req.params.id);
                res.json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * PATCH /listings/:id/state - Change state freely
         * Body: { state: 'draft' | 'published' | 'sold' }
         */
        this.changeState = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.changeState(uid, req.params.id, req.body.state);
                res.json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * DELETE /listings/:id - Soft delete
         */
        this.delete = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                await this.service.delete(uid, req.params.id);
                res.json({ success: true, message: 'Listing deleted' });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * GET /listings/:id - Detail
         */
        this.getById = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                const data = await this.service.getById(req.params.id, uid);
                if (uid) {
                    this.service.recordView(req.params.id, uid).catch(() => null);
                }
                res.json({ success: true, data });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * GET /listings - Browse published
         */
        this.list = async (req, res, next) => {
            try {
                const data = await this.service.findPublished(req.query);
                res.json({ success: true, data, count: data.length });
            }
            catch (err) {
                next(err);
            }
        };
        /**
         * GET /listings/my - My listings
         */
        this.myListings = async (req, res, next) => {
            try {
                const uid = req.user?.uid;
                if (!uid)
                    throw new app_error_1.UnauthorizedError();
                const data = await this.service.findMyListings(uid, req.query);
                res.json({ success: true, data, count: data.length });
            }
            catch (err) {
                next(err);
            }
        };
    }
}
exports.ListingsController = ListingsController;
//# sourceMappingURL=listings.controller.js.map
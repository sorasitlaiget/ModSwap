"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FollowsController = void 0;
const response_util_1 = require("../../utils/response.util");
class FollowsController {
    constructor(service) {
        this.service = service;
        this.follow = async (req, res, next) => {
            try {
                const followerUid = req.user.uid;
                const { sellerId } = req.params;
                await this.service.follow(followerUid, sellerId);
                res.status(201).json((0, response_util_1.successResponse)({ message: 'Followed' }));
            }
            catch (error) {
                next(error);
            }
        };
        this.unfollow = async (req, res, next) => {
            try {
                const followerUid = req.user.uid;
                const { sellerId } = req.params;
                await this.service.unfollow(followerUid, sellerId);
                res.json((0, response_util_1.successResponse)({ message: 'Unfollowed' }));
            }
            catch (error) {
                next(error);
            }
        };
        this.checkFollow = async (req, res, next) => {
            try {
                const followerUid = req.user.uid;
                const { sellerId } = req.params;
                const result = await this.service.checkFollow(followerUid, sellerId);
                res.json((0, response_util_1.successResponse)(result));
            }
            catch (error) {
                next(error);
            }
        };
    }
}
exports.FollowsController = FollowsController;
//# sourceMappingURL=follows.controller.js.map
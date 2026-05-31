"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FollowsService = void 0;
const app_error_1 = require("../../core/errors/app-error");
const logger_util_1 = require("../../utils/logger.util");
class FollowsService {
    constructor(followsRepo, usersRepo) {
        this.followsRepo = followsRepo;
        this.usersRepo = usersRepo;
    }
    async follow(followerUid, sellerUid) {
        if (followerUid === sellerUid) {
            throw new app_error_1.BadRequestError('Cannot follow yourself');
        }
        const seller = await this.usersRepo.findById(sellerUid);
        if (!seller)
            throw new app_error_1.NotFoundError('Seller not found');
        await this.followsRepo.follow(followerUid, sellerUid);
        logger_util_1.logger.info('Followed seller', { followerUid, sellerUid });
    }
    async unfollow(followerUid, sellerUid) {
        await this.followsRepo.unfollow(followerUid, sellerUid);
        logger_util_1.logger.info('Unfollowed seller', { followerUid, sellerUid });
    }
    async checkFollow(followerUid, sellerUid) {
        const isFollowing = await this.followsRepo.isFollowing(followerUid, sellerUid);
        return { isFollowing };
    }
}
exports.FollowsService = FollowsService;
//# sourceMappingURL=follows.service.js.map
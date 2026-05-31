"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createFollowsRouter = createFollowsRouter;
const express_1 = require("express");
const auth_middleware_1 = require("../../middleware/auth.middleware");
const users_repository_1 = require("../users/users.repository");
const follows_repository_1 = require("./follows.repository");
const follows_controller_1 = require("./follows.controller");
const follows_service_1 = require("./follows.service");
function createFollowsRouter() {
    const router = (0, express_1.Router)({ mergeParams: true });
    const followsRepo = new follows_repository_1.FollowsRepository();
    const usersRepo = new users_repository_1.UsersRepository();
    const service = new follows_service_1.FollowsService(followsRepo, usersRepo);
    const controller = new follows_controller_1.FollowsController(service);
    // POST   /users/:sellerId/follow
    // DELETE /users/:sellerId/follow
    // GET    /users/:sellerId/follow
    router.post('/', auth_middleware_1.authMiddleware, controller.follow);
    router.delete('/', auth_middleware_1.authMiddleware, controller.unfollow);
    router.get('/', auth_middleware_1.authMiddleware, controller.checkFollow);
    return router;
}
//# sourceMappingURL=follows.routes.js.map
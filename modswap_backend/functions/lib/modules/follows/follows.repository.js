"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FollowsRepository = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firebase_config_1 = require("../../config/firebase.config");
const constants_1 = require("../../config/constants");
class FollowsRepository {
    constructor() {
        this.db = firebase_config_1.db;
    }
    followingCol(followerUid) {
        return this.db
            .collection(constants_1.COLLECTIONS.USERS)
            .doc(followerUid)
            .collection(constants_1.SUBCOLLECTIONS.FOLLOWING);
    }
    followersCol(sellerUid) {
        return this.db
            .collection(constants_1.COLLECTIONS.USERS)
            .doc(sellerUid)
            .collection(constants_1.SUBCOLLECTIONS.FOLLOWERS);
    }
    async follow(followerUid, sellerUid) {
        const now = firestore_1.Timestamp.now();
        await Promise.all([
            this.followingCol(followerUid).doc(sellerUid).set({ sellerUid, addedAt: now }),
            this.followersCol(sellerUid).doc(followerUid).set({ followerUid, addedAt: now }),
        ]);
    }
    async unfollow(followerUid, sellerUid) {
        await Promise.all([
            this.followingCol(followerUid).doc(sellerUid).delete(),
            this.followersCol(sellerUid).doc(followerUid).delete(),
        ]);
    }
    async isFollowing(followerUid, sellerUid) {
        const snap = await this.followingCol(followerUid).doc(sellerUid).get();
        return snap.exists;
    }
    async getFollowerIds(sellerUid) {
        const snap = await this.followersCol(sellerUid).get();
        return snap.docs.map((d) => d.id);
    }
}
exports.FollowsRepository = FollowsRepository;
//# sourceMappingURL=follows.repository.js.map
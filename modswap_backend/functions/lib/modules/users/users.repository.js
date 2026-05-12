"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersRepository = void 0;
const firestore_1 = require("firebase-admin/firestore");
const firebase_config_1 = require("../../config/firebase.config");
const constants_1 = require("../../config/constants");
/**
 * Users Repository - จัดการ Firestore collection 'users'
 * ห้ามใส่ business logic ที่นี่
 */
class UsersRepository {
    constructor() {
        this.collection = firebase_config_1.firestore.collection(constants_1.COLLECTIONS.USERS);
    }
    /**
     * สร้าง user profile ใหม่ (ใช้ uid จาก Firebase Auth เป็น document id)
     */
    async create(uid, data) {
        const now = firestore_1.Timestamp.now();
        const user = {
            ...data,
            id: uid,
            createdAt: now,
            updatedAt: now,
        };
        await this.collection.doc(uid).set(user);
        return user;
    }
    async findById(uid) {
        const doc = await this.collection.doc(uid).get();
        if (!doc.exists)
            return null;
        return doc.data();
    }
    async exists(uid) {
        const doc = await this.collection.doc(uid).get();
        return doc.exists;
    }
    async findByStudentId(studentId, excludeUid) {
        const snapshot = await this.collection
            .where('studentId', '==', studentId)
            .limit(1)
            .get();
        if (snapshot.empty)
            return null;
        const doc = snapshot.docs[0];
        if (excludeUid && doc.id === excludeUid)
            return null;
        return doc.data();
    }
    async update(uid, data) {
        await this.collection.doc(uid).update({
            ...data,
            updatedAt: firestore_1.Timestamp.now(),
        });
    }
    async incrementTotalTrades(uid) {
        await this.collection.doc(uid).update({
            totalTrades: firestore_1.FieldValue.increment(1),
            updatedAt: firestore_1.Timestamp.now(),
        });
    }
    async delete(uid) {
        await this.collection.doc(uid).delete();
    }
}
exports.UsersRepository = UsersRepository;
//# sourceMappingURL=users.repository.js.map
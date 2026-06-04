"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendNotification = sendNotification;
const firestore_1 = require("firebase-admin/firestore");
const firebase_config_1 = require("../config/firebase.config");
const constants_1 = require("../config/constants");
async function sendNotification(opts) {
    await firebase_config_1.db
        .collection(constants_1.COLLECTIONS.USERS)
        .doc(opts.recipientUid)
        .collection(constants_1.SUBCOLLECTIONS.NOTIFICATIONS)
        .add({
        type: opts.type,
        title: opts.title,
        body: opts.body,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        isRead: false,
        ...(opts.deepLinkTarget !== undefined && { deepLinkTarget: opts.deepLinkTarget }),
        ...(opts.data !== undefined && { data: opts.data }),
    });
}
//# sourceMappingURL=notification.util.js.map
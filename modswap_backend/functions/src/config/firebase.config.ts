import * as admin from 'firebase-admin';

/**
 * Init Firebase Admin SDK
 * เรียกแค่ครั้งเดียวตอน app start
 */
if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const firestore = admin.firestore();
export const auth = admin.auth();

// ตั้งค่าให้ ignore undefined fields ตอนเขียน Firestore
firestore.settings({ ignoreUndefinedProperties: true });

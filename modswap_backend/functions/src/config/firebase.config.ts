import * as admin from 'firebase-admin';

/**
 * Init Firebase Admin SDK
 * เรียกแค่ครั้งเดียวตอน app start
 */
if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const firestore = db; // alias ไว้ใช้กับโค้ดเดิม
export const auth = admin.auth();

// ตั้งค่าให้ ignore undefined fields ตอนเขียน Firestore
db.settings({ ignoreUndefinedProperties: true });

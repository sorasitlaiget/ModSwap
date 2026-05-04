import * as functionsV1 from 'firebase-functions/v1';
import { auth, firestore } from '../../config/firebase.config';
import { COLLECTIONS, KMUTT_EMAIL_DOMAIN, USER_ROLES } from '../../config/constants';
import { logger } from '../../utils/logger.util';
import { Timestamp } from 'firebase-admin/firestore';

/**
 * Auth Trigger: ทำงานทันทีที่มีคน register สำเร็จ
 *
 * ⭐ นี่คือ "ด่านหลัก" ที่ป้องกันคนนอก KMUTT
 * เพราะคนสามารถเรียก Firebase Auth SDK ตรงข้าม Frontend ของเราได้
 *
 * Flow:
 * 1. ตรวจ email domain → ถ้าไม่ใช่ KMUTT ลบ user ทิ้งทันที
 * 2. สร้าง user profile ใน Firestore
 * 3. ตั้ง custom claims (role)
 */
export const onUserCreate = functionsV1
  .region('asia-southeast1')
  .auth.user()
  .onCreate(async (user) => {
    const { uid, email, displayName, photoURL } = user;

    logger.info('New user signup', { uid, email });

    // === Step 1: ตรวจ KMUTT email ===
    if (!email || !email.endsWith(KMUTT_EMAIL_DOMAIN)) {
      logger.warn('Non-KMUTT user attempted signup, deleting', { uid, email });
      try {
        await auth.deleteUser(uid);
        logger.info('Non-KMUTT user deleted', { uid });
      } catch (err) {
        logger.error('Failed to delete non-KMUTT user', err, { uid });
      }
      return;
    }

    // === Step 2: สร้าง user profile ใน Firestore ===
    try {
      const now = Timestamp.now();
      await firestore
        .collection(COLLECTIONS.USERS)
        .doc(uid)
        .set({
          id: uid,
          email,
          displayName: displayName ?? email.split('@')[0],
          photoURL: photoURL ?? null,
          lineId: null,
          studentId: null,
          faculty: null,
          rating: 0,
          totalReviews: 0,
          totalTrades: 0,
          createdAt: now,
          updatedAt: now,
        });

      // === Step 3: ตั้ง custom claims ===
      await auth.setCustomUserClaims(uid, {
        role: USER_ROLES.STUDENT,
        kmutt: true,
      });

      logger.info('User profile created successfully', { uid, email });
    } catch (err) {
      logger.error('Failed to create user profile', err, { uid });
      // ถ้าสร้าง profile ไม่ได้ ลบ Auth user ทิ้งเพื่อให้ retry ได้
      try {
        await auth.deleteUser(uid);
      } catch (deleteErr) {
        logger.error('Failed to cleanup auth user', deleteErr, { uid });
      }
    }
  });

/**
 * Auth Trigger: ทำงานเมื่อ user ถูกลบ
 * ลบ profile ใน Firestore ตาม
 */
export const onUserDelete = functionsV1
  .region('asia-southeast1')
  .auth.user()
  .onDelete(async (user) => {
    const { uid } = user;
    try {
      await firestore.collection(COLLECTIONS.USERS).doc(uid).delete();
      logger.info('User profile deleted', { uid });
    } catch (err) {
      logger.error('Failed to delete user profile', err, { uid });
    }
  });

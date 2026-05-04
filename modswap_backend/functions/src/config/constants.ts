/**
 * ค่าคงที่ที่ใช้ทั้งระบบ
 */

export const KMUTT_EMAIL_DOMAIN = '@mail.kmutt.ac.th';

export const COLLECTIONS = {
  USERS: 'users',
  LISTINGS: 'listings',
  TRADES: 'trades',
  REVIEWS: 'reviews',
} as const;

export const USER_ROLES = {
  STUDENT: 'student',
  ADMIN: 'admin',
} as const;

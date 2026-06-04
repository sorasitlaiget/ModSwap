/**
 * ค่าคงที่ที่ใช้ทั้งระบบ
 */

export const KMUTT_EMAIL_DOMAIN = '@mail.kmutt.ac.th';

export const COLLECTIONS = {
  USERS: 'users',
  LISTINGS: 'listings',
  DEALS: 'deals',
  TRADES: 'trades',
  REVIEWS: 'reviews',
  PENDING_RATINGS: 'pendingRatings',
} as const;

export const SUBCOLLECTIONS = {
  NOTIFICATIONS: 'notifications',
  WISHLIST: 'wishlist',
  DEVICES: 'devices',
} as const;

export const USER_ROLES = {
  STUDENT: 'student',
  ADMIN: 'admin',
} as const;

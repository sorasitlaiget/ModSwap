import { Timestamp } from 'firebase-admin/firestore';

/**
 * User Domain Model - represent user document ใน Firestore
 */
export interface User {
  id: string;
  email: string;
  displayName: string;
  photoURL: string | null;
  lineId: string | null;
  studentId: string | null;
  faculty: string | null;
  rating: number;
  totalReviews: number;
  totalTrades: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

/**
 * ข้อมูลที่ใช้สร้าง user profile ครั้งแรก (ตอน trigger ทำงาน)
 */
export type CreateUserData = Omit<User, 'id' | 'createdAt' | 'updatedAt'>;

/**
 * ข้อมูลที่ user แก้ไขเองได้
 */
export type UpdateUserProfileData = Partial<
  Pick<User, 'displayName' | 'lineId' | 'studentId' | 'faculty' | 'photoURL'>
>;

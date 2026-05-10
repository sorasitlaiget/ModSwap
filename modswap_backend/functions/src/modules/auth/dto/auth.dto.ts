/**
 * DTO = Data Transfer Object
 * รูปแบบข้อมูลที่ Backend ↔ Frontend ส่งหากัน
 */

/**
 * ข้อมูลที่ Frontend ส่งมาตอนเรียก /auth/complete-profile
 * (หลังจาก Firebase Auth สร้างบัญชีสำเร็จแล้ว)
 */
export interface CompleteProfileDto {
  displayName: string;
  studentId: string;
  faculty: string;
  lineId: string;
}

export interface UpdateProfileDto {
  displayName?: string;
  studentId?: string;
  faculty?: string;
  lineId?: string;
  photoURL?: string;
}

export interface ChangePasswordDto {
  newPassword: string;
}

/**
 * ข้อมูล user ที่ส่งกลับให้ frontend
 */
export interface UserProfileResponseDto {
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
  isProfileComplete: boolean;
  createdAt: string;
  updatedAt: string;
}

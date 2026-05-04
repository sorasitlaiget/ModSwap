/**
 * Helpers สำหรับ format API response ให้เป็นมาตรฐาน
 */

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

export function successResponse<T>(data: T): ApiResponse<T> {
  return { success: true, data };
}

export function errorResponse(code: string, message: string): ApiResponse {
  return { success: false, error: { code, message } };
}

import { z } from 'zod';

/**
 * Validation schemas สำหรับ auth endpoints
 */
export const passwordSchema = z.string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
  .regex(/[A-Z]/, 'Password must contain at least one uppercase letter');
  
export const completeProfileSchema = z.object({
  displayName: z
    .string()
    .min(1, 'Please enter your name')
    .max(50, 'Your name is too long')
    .trim(),
  studentId: z
    .string()
    .regex(/^\d{11}$/, 'StudenId must be 11 digit'),
  faculty: z
    .string()
    .min(1, 'Please select your faculty')
    .max(100)
    .trim(),
  lineId: z
    .string()
    .min(1, 'Please enter your LineID')
    .max(50)
    .trim(),
});

export const updateProfileSchema = z
  .object({
    displayName: z.string().min(1, 'Display name cannot be empty').max(50).trim().optional(),
    studentId: z.string().regex(/^\d{11}$/, 'Student ID must be 11 digits').optional(),
    faculty: z.string().min(1, 'Faculty cannot be empty').max(100).trim().optional(),
    lineId: z.string().min(1, 'Line ID cannot be empty').max(50).trim().optional(),
    photoURL: z.string().url('Invalid photo URL').optional().nullable(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field must be provided',
  });

export const changePasswordSchema = z.object({
  newPassword: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
});

import { z } from 'zod';
import { DEAL_TYPES } from './deals.types';

/**
 * Schema for POST /listings/:id/sold
 *
 * Conditional requirements:
 *   cash       → finalPrice required
 *   swap       → whatIGotReturn required, swapItemPhotoURL optional
 *   swap_cash  → finalPrice + whatIGotReturn required, swapItemPhotoURL optional
 */
export const markAsSoldSchema = z
  .object({
    dealType: z.enum(DEAL_TYPES, {
      errorMap: () => ({
        message: 'dealType must be one of: cash, swap, swap_cash',
      }),
    }),
    buyerLineId: z
      .string()
      .min(1, 'Buyer LINE ID is required')
      .max(100),
    dateCompleted: z
      .string()
      .regex(/^\d{4}-\d{2}-\d{2}$/, 'dateCompleted must be in YYYY-MM-DD format'),
    finalPrice: z.number().min(0).max(1_000_000).nullable().optional(),
    whatIGotReturn: z.string().min(1).max(500).nullable().optional(),
    swapItemPhotoURL: z.string().url('Invalid photo URL').nullable().optional(),
  })
  .superRefine((data, ctx) => {
    if (
      (data.dealType === 'cash' || data.dealType === 'swap_cash') &&
      data.finalPrice == null
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['finalPrice'],
        message: 'finalPrice is required for cash or swap+cash deals',
      });
    }

    if (
      (data.dealType === 'swap' || data.dealType === 'swap_cash') &&
      !data.whatIGotReturn?.trim()
    ) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['whatIGotReturn'],
        message: 'whatIGotReturn is required for swap deals',
      });
    }

    if (data.dealType === 'cash' && data.swapItemPhotoURL) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['swapItemPhotoURL'],
        message: 'swapItemPhotoURL is not applicable for cash deals',
      });
    }
  });

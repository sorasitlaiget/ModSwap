"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.markAsSoldSchema = void 0;
const zod_1 = require("zod");
const deals_types_1 = require("./deals.types");
/**
 * Schema for POST /listings/:id/sold
 *
 * Conditional requirements:
 *   cash       → finalPrice required
 *   swap       → whatIGotReturn required, swapItemPhotoURL optional
 *   swap_cash  → finalPrice + whatIGotReturn required, swapItemPhotoURL optional
 */
exports.markAsSoldSchema = zod_1.z
    .object({
    dealType: zod_1.z.enum(deals_types_1.DEAL_TYPES, {
        errorMap: () => ({
            message: 'dealType must be one of: cash, swap, swap_cash',
        }),
    }),
    buyerLineId: zod_1.z
        .string()
        .min(1, 'Buyer LINE ID is required')
        .max(100),
    dateCompleted: zod_1.z
        .string()
        .regex(/^\d{4}-\d{2}-\d{2}$/, 'dateCompleted must be in YYYY-MM-DD format'),
    finalPrice: zod_1.z.number().min(0).max(1000000).nullable().optional(),
    whatIGotReturn: zod_1.z.string().min(1).max(500).nullable().optional(),
    swapItemPhotoURL: zod_1.z.string().url('Invalid photo URL').nullable().optional(),
})
    .superRefine((data, ctx) => {
    if ((data.dealType === 'cash' || data.dealType === 'swap_cash') &&
        data.finalPrice == null) {
        ctx.addIssue({
            code: zod_1.z.ZodIssueCode.custom,
            path: ['finalPrice'],
            message: 'finalPrice is required for cash or swap+cash deals',
        });
    }
    if ((data.dealType === 'swap' || data.dealType === 'swap_cash') &&
        !data.whatIGotReturn?.trim()) {
        ctx.addIssue({
            code: zod_1.z.ZodIssueCode.custom,
            path: ['whatIGotReturn'],
            message: 'whatIGotReturn is required for swap deals',
        });
    }
    if (data.dealType === 'cash' && data.swapItemPhotoURL) {
        ctx.addIssue({
            code: zod_1.z.ZodIssueCode.custom,
            path: ['swapItemPhotoURL'],
            message: 'swapItemPhotoURL is not applicable for cash deals',
        });
    }
});
//# sourceMappingURL=deals.validator.js.map
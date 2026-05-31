"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.myListingsQuerySchema = exports.listingsQuerySchema = exports.changeStateSchema = exports.updateListingSchema = exports.publishListingSchema = exports.createDraftSchema = void 0;
const zod_1 = require("zod");
const listings_types_1 = require("./listings.types");
/**
 * Meeting point — must be within KMUTT campus
 */
const meetingPointSchema = zod_1.z.object({
    name: zod_1.z.string().min(1, 'Meeting point name required').max(200),
    latitude: zod_1.z
        .number()
        .min(listings_types_1.KMUTT_BOUNDS.minLat, 'Meeting point must be within KMUTT campus')
        .max(listings_types_1.KMUTT_BOUNDS.maxLat, 'Meeting point must be within KMUTT campus'),
    longitude: zod_1.z
        .number()
        .min(listings_types_1.KMUTT_BOUNDS.minLng, 'Meeting point must be within KMUTT campus')
        .max(listings_types_1.KMUTT_BOUNDS.maxLng, 'Meeting point must be within KMUTT campus'),
    placeId: zod_1.z.string().max(200).nullable().optional(),
});
/**
 * Schema for creating a DRAFT (lenient — only title required)
 */
exports.createDraftSchema = zod_1.z.object({
    title: zod_1.z.string().min(1, 'Title is required').max(100),
    description: zod_1.z.string().max(2000).nullable().optional(),
    category: zod_1.z.enum(listings_types_1.LISTING_CATEGORIES).nullable().optional(),
    type: zod_1.z.enum(listings_types_1.LISTING_TYPES).nullable().optional(),
    price: zod_1.z.number().min(0).max(1000000).nullable().optional(),
    swapPreference: zod_1.z.string().max(500).nullable().optional(),
    condition: zod_1.z.enum(listings_types_1.LISTING_CONDITIONS).nullable().optional(),
    images: zod_1.z
        .array(zod_1.z.string().url('Invalid image URL'))
        .max(listings_types_1.MAX_IMAGES_PER_LISTING, `Maximum ${listings_types_1.MAX_IMAGES_PER_LISTING} images`)
        .optional()
        .default([]),
    meetingPoint: meetingPointSchema.nullable().optional(),
});
/**
 * Schema for PUBLISHING (strict)
 */
exports.publishListingSchema = zod_1.z
    .object({
    title: zod_1.z.string().min(3, 'Title must be at least 3 characters').max(100),
    description: zod_1.z
        .string()
        .min(10, 'Description must be at least 10 characters')
        .max(2000),
    category: zod_1.z.enum(listings_types_1.LISTING_CATEGORIES, {
        errorMap: () => ({ message: 'Please select a category' }),
    }),
    type: zod_1.z.enum(listings_types_1.LISTING_TYPES, {
        errorMap: () => ({ message: 'Please select listing type' }),
    }),
    price: zod_1.z.number().min(0).max(1000000).nullable(),
    swapPreference: zod_1.z.string().max(500).nullable(),
    condition: zod_1.z.enum(listings_types_1.LISTING_CONDITIONS, {
        errorMap: () => ({ message: 'Please select item condition' }),
    }),
    images: zod_1.z
        .array(zod_1.z.string().url())
        .min(listings_types_1.MIN_IMAGES_FOR_PUBLISH, 'At least 1 image required')
        .max(listings_types_1.MAX_IMAGES_PER_LISTING),
    meetingPoint: meetingPointSchema,
})
    .superRefine((data, ctx) => {
    if (data.type === 'sell' && data.price === null) {
        ctx.addIssue({
            code: zod_1.z.ZodIssueCode.custom,
            path: ['price'],
            message: 'Price is required for selling',
        });
    }
    if (data.type === 'trade') {
        if (!data.swapPreference || data.swapPreference.trim().length === 0) {
            ctx.addIssue({
                code: zod_1.z.ZodIssueCode.custom,
                path: ['swapPreference'],
                message: 'Please specify what you want to swap for',
            });
        }
    }
    if (data.type === 'both') {
        if (data.price === null) {
            ctx.addIssue({
                code: zod_1.z.ZodIssueCode.custom,
                path: ['price'],
                message: 'Price is required',
            });
        }
        if (!data.swapPreference || data.swapPreference.trim().length === 0) {
            ctx.addIssue({
                code: zod_1.z.ZodIssueCode.custom,
                path: ['swapPreference'],
                message: 'Please specify what you want to swap for',
            });
        }
    }
});
/**
 * Schema for UPDATE (partial)
 */
exports.updateListingSchema = zod_1.z.object({
    title: zod_1.z.string().min(1).max(100).optional(),
    description: zod_1.z.string().max(2000).nullable().optional(),
    category: zod_1.z.enum(listings_types_1.LISTING_CATEGORIES).nullable().optional(),
    type: zod_1.z.enum(listings_types_1.LISTING_TYPES).nullable().optional(),
    price: zod_1.z.number().min(0).max(1000000).nullable().optional(),
    swapPreference: zod_1.z.string().max(500).nullable().optional(),
    condition: zod_1.z.enum(listings_types_1.LISTING_CONDITIONS).nullable().optional(),
    images: zod_1.z.array(zod_1.z.string().url()).max(listings_types_1.MAX_IMAGES_PER_LISTING).optional(),
    meetingPoint: meetingPointSchema.nullable().optional(),
});
/**
 * Schema for changing listing state
 * Allowed: draft, published, sold
 * Not allowed: removed (use DELETE endpoint instead)
 */
exports.changeStateSchema = zod_1.z.object({
    state: zod_1.z.enum(['draft', 'published', 'sold'], {
        errorMap: () => ({
            message: 'State must be one of: draft, published, sold',
        }),
    }),
});
/**
 * Browse query
 */
exports.listingsQuerySchema = zod_1.z.object({
    category: zod_1.z.enum(listings_types_1.LISTING_CATEGORIES).optional(),
    type: zod_1.z.enum(listings_types_1.LISTING_TYPES).optional(),
    search: zod_1.z.string().max(100).optional(),
    limit: zod_1.z.coerce.number().min(1).max(50).default(20),
    cursor: zod_1.z.string().optional(),
});
/**
 * My listings query
 */
exports.myListingsQuerySchema = zod_1.z.object({
    state: zod_1.z.enum(['draft', 'published', 'sold', 'all']).default('all'),
    limit: zod_1.z.coerce.number().min(1).max(50).default(20),
    cursor: zod_1.z.string().optional(),
});
//# sourceMappingURL=listings.validator.js.map
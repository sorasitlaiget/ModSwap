import { z } from 'zod';
import {
  KMUTT_BOUNDS,
  LISTING_CATEGORIES,
  LISTING_CONDITIONS,
  LISTING_TYPES,
  MAX_IMAGES_PER_LISTING,
  MIN_IMAGES_FOR_PUBLISH,
} from './listings.types';

/**
 * Meeting point — must be within KMUTT campus
 */
const meetingPointSchema = z.object({
  name: z.string().min(1, 'Meeting point name required').max(200),
  latitude: z
    .number()
    .min(KMUTT_BOUNDS.minLat, 'Meeting point must be within KMUTT campus')
    .max(KMUTT_BOUNDS.maxLat, 'Meeting point must be within KMUTT campus'),
  longitude: z
    .number()
    .min(KMUTT_BOUNDS.minLng, 'Meeting point must be within KMUTT campus')
    .max(KMUTT_BOUNDS.maxLng, 'Meeting point must be within KMUTT campus'),
  placeId: z.string().max(200).nullable().optional(),
});

/**
 * Schema for creating a DRAFT (lenient — only title required)
 */
export const createDraftSchema = z.object({
  title: z.string().min(1, 'Title is required').max(100),
  description: z.string().max(2000).nullable().optional(),
  category: z.enum(LISTING_CATEGORIES).nullable().optional(),
  type: z.enum(LISTING_TYPES).nullable().optional(),
  price: z.number().min(0).max(1_000_000).nullable().optional(),
  swapPreference: z.string().max(500).nullable().optional(),
  condition: z.enum(LISTING_CONDITIONS).nullable().optional(),
  images: z
    .array(z.string().url('Invalid image URL'))
    .max(MAX_IMAGES_PER_LISTING, `Maximum ${MAX_IMAGES_PER_LISTING} images`)
    .optional()
    .default([]),
  meetingPoint: meetingPointSchema.nullable().optional(),
});

/**
 * Schema for PUBLISHING (strict)
 */
export const publishListingSchema = z
  .object({
    title: z.string().min(3, 'Title must be at least 3 characters').max(100),
    description: z
      .string()
      .min(10, 'Description must be at least 10 characters')
      .max(2000),
    category: z.enum(LISTING_CATEGORIES, {
      errorMap: () => ({ message: 'Please select a category' }),
    }),
    type: z.enum(LISTING_TYPES, {
      errorMap: () => ({ message: 'Please select listing type' }),
    }),
    price: z.number().min(0).max(1_000_000).nullable(),
    swapPreference: z.string().max(500).nullable(),
    condition: z.enum(LISTING_CONDITIONS, {
      errorMap: () => ({ message: 'Please select item condition' }),
    }),
    images: z
      .array(z.string().url())
      .min(MIN_IMAGES_FOR_PUBLISH, 'At least 1 image required')
      .max(MAX_IMAGES_PER_LISTING),
    meetingPoint: meetingPointSchema,
  })
  .superRefine((data, ctx) => {
    if (data.type === 'sell' && data.price === null) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['price'],
        message: 'Price is required for selling',
      });
    }

    if (data.type === 'trade') {
      if (!data.swapPreference || data.swapPreference.trim().length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['swapPreference'],
          message: 'Please specify what you want to swap for',
        });
      }
    }

    if (data.type === 'both') {
      if (data.price === null) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['price'],
          message: 'Price is required',
        });
      }
      if (!data.swapPreference || data.swapPreference.trim().length === 0) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['swapPreference'],
          message: 'Please specify what you want to swap for',
        });
      }
    }
  });

/**
 * Schema for UPDATE (partial)
 */
export const updateListingSchema = z.object({
  title: z.string().min(1).max(100).optional(),
  description: z.string().max(2000).nullable().optional(),
  category: z.enum(LISTING_CATEGORIES).nullable().optional(),
  type: z.enum(LISTING_TYPES).nullable().optional(),
  price: z.number().min(0).max(1_000_000).nullable().optional(),
  swapPreference: z.string().max(500).nullable().optional(),
  condition: z.enum(LISTING_CONDITIONS).nullable().optional(),
  images: z.array(z.string().url()).max(MAX_IMAGES_PER_LISTING).optional(),
  meetingPoint: meetingPointSchema.nullable().optional(),
});

/**
 * Schema for changing listing state
 * Allowed: draft, published, sold
 * Not allowed: removed (use DELETE endpoint instead)
 */
export const changeStateSchema = z.object({
  state: z.enum(['draft', 'published', 'sold'], {
    errorMap: () => ({
      message: 'State must be one of: draft, published, sold',
    }),
  }),
});

/**
 * Browse query
 */
export const listingsQuerySchema = z.object({
  category: z.enum(LISTING_CATEGORIES).optional(),
  type: z.enum(LISTING_TYPES).optional(),
  search: z.string().max(100).optional(),
  limit: z.coerce.number().min(1).max(50).default(20),
  cursor: z.string().optional(),
});

/**
 * My listings query
 */
export const myListingsQuerySchema = z.object({
  state: z.enum(['draft', 'published', 'sold', 'all']).default('all'),
  limit: z.coerce.number().min(1).max(50).default(20),
  cursor: z.string().optional(),
});

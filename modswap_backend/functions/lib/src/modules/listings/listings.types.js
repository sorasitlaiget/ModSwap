"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.KMUTT_BOUNDS = exports.MIN_IMAGES_FOR_PUBLISH = exports.MAX_IMAGES_PER_LISTING = exports.LISTING_STATES = exports.LISTING_CONDITIONS = exports.LISTING_TYPES = exports.LISTING_CATEGORIES = void 0;
exports.isWithinKmutt = isWithinKmutt;
/**
 * Listing Domain Model
 */
exports.LISTING_CATEGORIES = [
    'textbooks',
    'electronics',
    'fashion',
    'dorm',
    'vehicles',
    'others',
];
exports.LISTING_TYPES = ['sell', 'trade', 'both'];
exports.LISTING_CONDITIONS = ['new', 'like-new', 'used'];
exports.LISTING_STATES = [
    'draft',
    'published',
    'sold',
    'removed',
];
/**
 * Constraints
 */
exports.MAX_IMAGES_PER_LISTING = 10;
exports.MIN_IMAGES_FOR_PUBLISH = 1;
/**
 * KMUTT Bangmod campus bounds
 */
exports.KMUTT_BOUNDS = {
    minLat: 13.640,
    maxLat: 13.660,
    minLng: 100.485,
    maxLng: 100.510,
};
/**
 * Helper: check if coordinates are within KMUTT
 */
function isWithinKmutt(lat, lng) {
    return (lat >= exports.KMUTT_BOUNDS.minLat &&
        lat <= exports.KMUTT_BOUNDS.maxLat &&
        lng >= exports.KMUTT_BOUNDS.minLng &&
        lng <= exports.KMUTT_BOUNDS.maxLng);
}
//# sourceMappingURL=listings.types.js.map
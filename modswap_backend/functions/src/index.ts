import { onRequest } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2';
import { createApp } from './app';

// ตั้ง region default ให้ Cloud Functions ทั้งหมด
setGlobalOptions({ region: 'asia-southeast1', maxInstances: 10 });

// === HTTP API ===
// URL จะเป็น: https://asia-southeast1-{project-id}.cloudfunctions.net/api
export const api = onRequest(createApp());

// === Auth Triggers ===
export { onUserCreate, onUserDelete } from './triggers/auth/on-user-create.trigger';

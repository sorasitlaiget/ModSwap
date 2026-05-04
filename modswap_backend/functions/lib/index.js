"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserDelete = exports.onUserCreate = exports.api = void 0;
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const app_1 = require("./app");
// ตั้ง region default ให้ Cloud Functions ทั้งหมด
(0, v2_1.setGlobalOptions)({ region: 'asia-southeast1', maxInstances: 10 });
// === HTTP API ===
// URL จะเป็น: https://asia-southeast1-{project-id}.cloudfunctions.net/api
exports.api = (0, https_1.onRequest)((0, app_1.createApp)());
// === Auth Triggers ===
var on_user_create_trigger_1 = require("./triggers/auth/on-user-create.trigger");
Object.defineProperty(exports, "onUserCreate", { enumerable: true, get: function () { return on_user_create_trigger_1.onUserCreate; } });
Object.defineProperty(exports, "onUserDelete", { enumerable: true, get: function () { return on_user_create_trigger_1.onUserDelete; } });
//# sourceMappingURL=index.js.map
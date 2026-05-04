import * as functions from 'firebase-functions';

/**
 * Logger wrapper - ใช้ Firebase Functions logger
 * จะเห็นใน Firebase Console > Functions > Logs
 */
export const logger = {
  info: (message: string, data?: object) => {
    functions.logger.info(message, data);
  },
  warn: (message: string, data?: object) => {
    functions.logger.warn(message, data);
  },
  error: (message: string, error?: unknown, data?: object) => {
    functions.logger.error(message, { error, ...data });
  },
  debug: (message: string, data?: object) => {
    functions.logger.debug(message, data);
  },
};

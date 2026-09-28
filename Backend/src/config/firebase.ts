import * as admin from 'firebase-admin';
import { env } from './env';
import { logger } from '../utils/logger';

export const initFirebase = (): void => {
  try {
    if (admin.apps.length > 0) return;

    if (env.FIREBASE_PROJECT_ID && env.FIREBASE_CLIENT_EMAIL && env.FIREBASE_PRIVATE_KEY) {
      const privateKey = env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: env.FIREBASE_PROJECT_ID,
          clientEmail: env.FIREBASE_CLIENT_EMAIL,
          privateKey,
        }),
      });
      logger.info('🔥 Firebase Admin initialized successfully');
    } else {
      logger.warn('⚠️ Firebase credentials missing. Push notifications / App Check will run in stub mode.');
    }
  } catch (error) {
    logger.error('❌ Failed to initialize Firebase Admin:', error);
  }
};

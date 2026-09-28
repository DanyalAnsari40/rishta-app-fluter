import mongoose from 'mongoose';
import { env } from './env';
import { logger } from '../utils/logger';

export const connectDB = async (): Promise<void> => {
  try {
    const conn = await mongoose.connect(env.MONGODB_URI, {
      serverSelectionTimeoutMS: 3000,
    });
    logger.info(`🍃 MongoDB Connected: ${conn.connection.host} / ${conn.connection.name}`);
  } catch (error: any) {
    logger.error(`❌ MongoDB Connection Warning (${error.message}). Server running with offline DB fallback.`);
  }
};

mongoose.connection.on('disconnected', () => {
  logger.warn('⚠️ MongoDB disconnected. Attempting reconnect...');
});

mongoose.connection.on('error', (err) => {
  logger.error('❌ MongoDB Connection Event Error:', err);
});

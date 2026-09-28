import http from 'http';
import app from './app';
import { env } from './config/env';
import { connectDB } from './config/db';
import { initCloudinary } from './config/cloudinary';
import { initFirebase } from './config/firebase';
import { logger } from './utils/logger';

const server = http.createServer(app);

const startServer = async () => {
  server.listen(env.PORT, () => {
    logger.info(`🚀 Server running in [${env.NODE_ENV}] mode on port ${env.PORT}`);
    logger.info(`🔗 Health route available at: http://localhost:${env.PORT}/api/v1/health`);
    logger.info(`💬 Chat API initialized (Polling Mode)`);
  });

  // Initialize MongoDB Connection asynchronously
  connectDB();

  // Initialize Third-Party Integrations
  initCloudinary();
  initFirebase();
};

// Handle Unhandled Rejections & Uncaught Exceptions
process.on('uncaughtException', (err: Error) => {
  logger.error('❌ Uncaught Exception! Shutting down server...', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason: any) => {
  logger.error('❌ Unhandled Rejection! Shutting down server...', reason);
  server.close(() => {
    process.exit(1);
  });
});

// Graceful Shutdown
process.on('SIGTERM', () => {
  logger.info('🛑 SIGTERM received. Shutting down gracefully...');
  server.close(() => {
    logger.info('💥 Process terminated!');
  });
});

startServer();

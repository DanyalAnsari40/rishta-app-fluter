import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import app from './app';
import { env } from './config/env';
import { connectDB } from './config/db';
import { initCloudinary } from './config/cloudinary';
import { initFirebase } from './config/firebase';
import { initChatSockets } from './sockets/chat.socket';
import { logger } from './utils/logger';

const server = http.createServer(app);

// Initialize Socket.IO Server
const io = new SocketIOServer(server, {
  cors: {
    origin: env.CLIENT_URL || '*',
    credentials: true,
  },
});

initChatSockets(io);

const startServer = async () => {
  server.listen(env.PORT, () => {
    logger.info(`🚀 Server running in [${env.NODE_ENV}] mode on port ${env.PORT}`);
    logger.info(`🔗 Health route available at: http://localhost:${env.PORT}/api/v1/health`);
    logger.info(`💬 Socket.IO Realtime Chat initialized`);
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

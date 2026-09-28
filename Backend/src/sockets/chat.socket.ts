import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { User } from '../models/user.model';
import { Conversation } from '../models/conversation.model';
import { Message } from '../models/message.model';
import { Interest } from '../models/interest.model';
import { Block } from '../models/block.model';
import { NotificationService } from '../services/notification.service';
import { logger } from '../utils/logger';

interface AuthenticatedSocket extends Socket {
  userId?: string;
  userEmail?: string;
}

export const initChatSockets = (io: Server) => {
  // Map of userId -> Set of socket IDs
  const activeSockets = new Map<string, Set<string>>();

  // Socket authentication middleware
  io.use(async (socket: AuthenticatedSocket, next) => {
    try {
      const token =
        socket.handshake.auth?.token ||
        socket.handshake.headers?.authorization?.replace('Bearer ', '') ||
        (socket.handshake.query?.token as string);

      if (!token) {
        return next(new Error('Authentication token required for Socket.IO connection'));
      }

      const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as { userId: string; email: string };
      const user = await User.findById(decoded.userId);

      if (!user || user.status !== 'active') {
        return next(new Error('User inactive or unauthorized'));
      }

      socket.userId = user._id.toString();
      socket.userEmail = user.email;
      return next();
    } catch (err) {
      return next(new Error('Invalid Socket.IO authentication token'));
    }
  });

  io.on('connection', (socket: AuthenticatedSocket) => {
    const userId = socket.userId!;
    logger.info(`🔌 Socket connected: User ${userId} (${socket.id})`);

    // Track user socket
    if (!activeSockets.has(userId)) {
      activeSockets.set(userId, new Set());
    }
    activeSockets.get(userId)!.add(socket.id);
    socket.join(userId);

    // Event: Send Message
    socket.on('message:send', async (data: { receiverId: string; text: string; imageUrl?: string }, callback) => {
      try {
        const { receiverId, text, imageUrl } = data;

        if (!text && !imageUrl) {
          if (callback) callback({ success: false, message: 'Message text or image required' });
          return;
        }

        // 1. Verify mutual interest acceptance (CRITICAL BUSINESS RULE)
        const mutualInterest = await Interest.findOne({
          $or: [
            { senderId: userId, receiverId: receiverId, status: 'accepted' },
            { senderId: receiverId, receiverId: userId, status: 'accepted' },
          ],
        });

        if (!mutualInterest) {
          if (callback) callback({ success: false, message: 'Chat opens only after mutual interest is accepted' });
          return;
        }

        // 2. Check block status
        const isBlocked = await Block.findOne({
          $or: [
            { blockerId: userId, blockedId: receiverId },
            { blockerId: receiverId, blockedId: userId },
          ],
        });

        if (isBlocked) {
          if (callback) callback({ success: false, message: 'Messaging is blocked' });
          return;
        }

        // 3. Find or create Conversation
        let conversation = await Conversation.findOne({
          participants: { $all: [userId, receiverId] },
        });

        if (!conversation) {
          conversation = await Conversation.create({
            participants: [userId, receiverId],
            lastMessage: text,
            lastMessageAt: new Date(),
            lastMessageSenderId: userId,
          });
        } else {
          conversation.lastMessage = text;
          conversation.lastMessageAt = new Date();
          conversation.lastMessageSenderId = userId as any;
          await conversation.save();
        }

        // 4. Save Message
        const messageDoc = await Message.create({
          conversationId: conversation._id,
          senderId: userId,
          receiverId,
          text,
          imageUrl,
          read: false,
        });

        const messagePayload = {
          messageId: messageDoc._id,
          conversationId: conversation._id,
          senderId: userId,
          receiverId,
          text,
          imageUrl,
          read: false,
          createdAt: messageDoc.createdAt,
        };

        // 5. Emit message:new to recipient room
        io.to(receiverId).emit('message:new', messagePayload);

        // 6. Send push notification if recipient is offline or not active
        const recipientSockets = activeSockets.get(receiverId);
        if (!recipientSockets || recipientSockets.size === 0) {
          NotificationService.sendNotification({
            recipientId: receiverId,
            senderId: userId,
            type: 'new_message',
            title: 'New Message',
            body: text.length > 50 ? `${text.substring(0, 50)}...` : text,
            deepLink: `/chat/${conversation._id}`,
          });
        }

        if (callback) callback({ success: true, data: messagePayload });
      } catch (error: any) {
        logger.error('Error handling message:send:', error);
        if (callback) callback({ success: false, message: error.message });
      }
    });

    // Event: Typing Start
    socket.on('typing:start', (data: { receiverId: string }) => {
      io.to(data.receiverId).emit('typing:start', { userId });
    });

    // Event: Typing Stop
    socket.on('typing:stop', (data: { receiverId: string }) => {
      io.to(data.receiverId).emit('typing:stop', { userId });
    });

    // Event: Disconnect
    socket.on('disconnect', () => {
      const userSet = activeSockets.get(userId);
      if (userSet) {
        userSet.delete(socket.id);
        if (userSet.size === 0) {
          activeSockets.delete(userId);
        }
      }
      logger.info(`🔌 Socket disconnected: User ${userId} (${socket.id})`);
    });
  });
};

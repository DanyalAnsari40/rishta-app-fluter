import * as admin from 'firebase-admin';
import mongoose from 'mongoose';
import { Notification, NotificationType } from '../models/notification.model';
import { DeviceToken } from '../models/deviceToken.model';
import { logger } from '../utils/logger';

export class NotificationService {
  /**
   * Dispatches an in-app notification and FCM push notification to the recipient.
   */
  static async sendNotification({
    recipientId,
    senderId,
    type,
    title,
    body,
    deepLink,
  }: {
    recipientId: string | mongoose.Types.ObjectId;
    senderId?: string | mongoose.Types.ObjectId;
    type: NotificationType;
    title: string;
    body: string;
    deepLink?: string;
  }) {
    try {
      // 1. Save in-app notification document
      const notification = await Notification.create({
        recipientId,
        senderId,
        type,
        title,
        body,
        deepLink,
        isRead: false,
      });

      // 2. Fetch recipient's registered device tokens
      const tokens = await DeviceToken.find({ userId: recipientId }).select('token');
      const tokenStrings = tokens.map((t) => t.token);

      if (tokenStrings.length === 0) {
        logger.info(`ℹ️ No FCM tokens registered for user ${recipientId}. In-app notification created.`);
        return notification;
      }

      // 3. Dispatch FCM Push Notification via Firebase Admin SDK
      if (admin.apps.length > 0) {
        const payload: admin.messaging.MulticastMessage = {
          tokens: tokenStrings,
          notification: {
            title,
            body,
          },
          data: {
            type,
            deepLink: deepLink || '',
            notificationId: notification._id.toString(),
          },
        };

        const response = await admin.messaging().sendEachForMulticast(payload);
        logger.info(`🔔 FCM Push Notification sent to ${recipientId}. Success count: ${response.successCount}`);
      } else {
        logger.info(`[STUB PUSH NOTIFICATION] To: ${recipientId} | Title: ${title} | Body: ${body}`);
      }

      return notification;
    } catch (error) {
      logger.error(`❌ Failed to send notification to ${recipientId}:`, error);
    }
  }

  /**
   * Broadcast push notification to all device tokens registered in system
   */
  static async broadcastNotification(title: string, body: string): Promise<void> {
    try {
      const tokens = await DeviceToken.find().select('token');
      const tokenStrings = Array.from(new Set(tokens.map((t) => t.token)));

      if (tokenStrings.length === 0) {
        logger.info('ℹ️ No FCM tokens registered for broadcast.');
        return;
      }

      if (admin.apps.length > 0) {
        const payload: admin.messaging.MulticastMessage = {
          tokens: tokenStrings,
          notification: { title, body },
          data: { type: 'system', deepLink: '' },
        };
        const response = await admin.messaging().sendEachForMulticast(payload);
        logger.info(`📢 Broadcast FCM notification sent. Success count: ${response.successCount}`);
      } else {
        logger.info(`[STUB BROADCAST NOTIFICATION] Title: ${title} | Body: ${body}`);
      }
    } catch (error) {
      logger.error('❌ Failed to send broadcast notification:', error);
    }
  }
}


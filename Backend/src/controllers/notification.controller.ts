import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Notification } from '../models/notification.model';
import { DeviceToken } from '../models/deviceToken.model';
import { ApiResponse } from '../utils/apiResponse';

export const getNotifications = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;

    const notifications = await Notification.find({ recipientId: userId })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();

    const unreadCount = await Notification.countDocuments({ recipientId: userId, isRead: false });

    return ApiResponse.success(res, 'Notifications retrieved successfully', {
      notifications,
      unreadCount,
    });
  } catch (error) {
    next(error);
  }
};

export const markNotificationRead = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { notificationId } = req.params;

    await Notification.updateOne({ _id: notificationId, recipientId: userId }, { $set: { isRead: true } });
    return ApiResponse.success(res, 'Notification marked as read');
  } catch (error) {
    next(error);
  }
};

export const markAllNotificationsRead = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;

    await Notification.updateMany({ recipientId: userId, isRead: false }, { $set: { isRead: true } });
    return ApiResponse.success(res, 'All notifications marked as read');
  } catch (error) {
    next(error);
  }
};

export const registerDeviceToken = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { token, platform } = req.body;

    const deviceToken = await DeviceToken.findOneAndUpdate(
      { token },
      { userId, token, platform: platform || 'android' },
      { upsert: true, new: true }
    );

    return ApiResponse.success(res, 'Device token registered successfully', deviceToken);
  } catch (error) {
    next(error);
  }
};

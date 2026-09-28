import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Conversation } from '../models/conversation.model';
import { Message } from '../models/message.model';
import { Interest } from '../models/interest.model';
import { Block } from '../models/block.model';
import { Profile } from '../models/profile.model';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';

export const getConversations = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;

    const conversations = await Conversation.find({ participants: userId })
      .sort({ lastMessageAt: -1 })
      .lean();

    const formattedList = await Promise.all(
      conversations.map(async (conv) => {
        const targetUserId = conv.participants.find((p) => p.toString() !== userId.toString());

        const profile = await Profile.findOne({ userId: targetUserId }).lean();
        let name = profile?.basicInfo?.fullName || 'Member';
        const parts = name.trim().split(' ');
        if (parts.length > 1) {
          name = `${parts[0]} ${parts[parts.length - 1][0]}.`;
        }

        const unreadCount = await Message.countDocuments({
          conversationId: conv._id,
          receiverId: userId,
          read: false,
        });

        return {
          conversationId: conv._id,
          targetUserId,
          name,
          primaryPhotoUrl: profile?.photos?.find((ph: any) => ph.isPrimary)?.secureUrl || profile?.photos?.[0]?.secureUrl || null,
          lastMessage: conv.lastMessage || '',
          lastMessageAt: conv.lastMessageAt,
          unreadCount,
        };
      })
    );

    return ApiResponse.success(res, 'Conversations list retrieved successfully', formattedList);
  } catch (error) {
    next(error);
  }
};

export const getMessages = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { conversationId } = req.params;
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 50;
    const skip = (page - 1) * limit;

    const conversation = await Conversation.findOne({
      _id: conversationId,
      participants: userId,
    });

    if (!conversation) {
      throw ApiError.notFound('Conversation not found');
    }

    const messages = await Message.find({ conversationId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Message.countDocuments({ conversationId });

    return ApiResponse.success(res, 'Messages retrieved successfully', {
      messages: messages.reverse(),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

export const markMessagesRead = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { conversationId } = req.params;

    await Message.updateMany(
      { conversationId, receiverId: userId, read: false },
      { $set: { read: true } }
    );

    return ApiResponse.success(res, 'Messages marked as read');
  } catch (error) {
    next(error);
  }
};

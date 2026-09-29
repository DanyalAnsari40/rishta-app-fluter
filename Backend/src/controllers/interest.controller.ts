import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Interest } from '../models/interest.model';
import { Block } from '../models/block.model';
import { User } from '../models/user.model';
import { Profile } from '../models/profile.model';
import { Conversation } from '../models/conversation.model';
import { Notification } from '../models/notification.model';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';

/**
 * Sends an interest / message request to a target user
 */
export const sendInterest = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const senderId = req.user!._id;
    const { targetUserId } = req.body;

    if (senderId.toString() === targetUserId) {
      throw ApiError.badRequest('You cannot send an interest to yourself');
    }

    const receiver = await User.findById(targetUserId);
    if (!receiver || receiver.status !== 'active') {
      throw ApiError.notFound('Target user not found or no longer active');
    }

    // Check if blocked in either direction
    const isBlocked = await Block.findOne({
      $or: [
        { blockerId: senderId, blockedId: targetUserId },
        { blockerId: targetUserId, blockedId: senderId },
      ],
    });

    if (isBlocked) {
      throw ApiError.forbidden('Action not allowed');
    }

    // Check existing interest
    let interest = await Interest.findOne({
      $or: [
        { senderId, receiverId: targetUserId },
        { senderId: targetUserId, receiverId: senderId },
      ],
    });

    let alreadyPending = false;
    if (interest) {
      if (interest.status === 'pending') {
        alreadyPending = true;
      } else if (interest.status === 'accepted') {
        return ApiResponse.success(res, 'Connection already established!', interest);
      } else {
        interest.status = 'pending';
        interest.senderId = senderId;
        interest.receiverId = targetUserId;
        await interest.save();
      }
    } else {
      interest = await Interest.create({
        senderId,
        receiverId: targetUserId,
        status: 'pending',
      });
    }

    // Always ensure notification is created for receiver so it shows in Alerts
    const senderProfile = await Profile.findOne({ userId: senderId }).lean();
    let senderName = senderProfile?.basicInfo?.fullName || 'Someone';
    const nameParts = senderName.trim().split(' ');
    if (nameParts.length > 1) {
      senderName = `${nameParts[0]} ${nameParts[nameParts.length - 1][0]}.`;
    }

    await Notification.create({
      recipientId: targetUserId,
      senderId,
      type: 'new_interest',
      title: 'New Interest Request ❤️',
      body: `${senderName} sent you an interest request. Check Received tab to respond.`,
      deepLink: '/interests?type=received',
    });

    if (alreadyPending) {
      return ApiResponse.success(res, 'Interest request is pending. Notification sent to target user.', interest);
    }

    return ApiResponse.success(res, 'Interest request sent successfully!', interest, 201);
  } catch (error) {
    next(error);
  }
};

/**
 * Accepts a received interest and creates a conversation connection
 */
export const acceptInterest = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const receiverId = req.user!._id;
    const { interestId } = req.params;

    const interest = await Interest.findOne({
      _id: interestId,
      receiverId,
      status: 'pending',
    });

    if (!interest) {
      throw ApiError.notFound('Pending interest request not found');
    }

    interest.status = 'accepted';
    await interest.save();

    // Ensure Conversation record exists in database
    let conversation = await Conversation.findOne({
      participants: { $all: [interest.senderId, interest.receiverId] },
    });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [interest.senderId, interest.receiverId],
        lastMessage: 'Connection successful! You can now start chatting.',
        lastMessageAt: new Date(),
      });
    }

    // Get details of sender to send notification & return to frontend
    const senderProfile = await Profile.findOne({ userId: interest.senderId }).lean();
    let senderName = senderProfile?.basicInfo?.fullName || 'Member';
    const nameParts = senderName.trim().split(' ');
    if (nameParts.length > 1) {
      senderName = `${nameParts[0]} ${nameParts[nameParts.length - 1][0]}.`;
    }

    // Get details of acceptor to send notification to sender
    const acceptorProfile = await Profile.findOne({ userId: receiverId }).lean();
    let acceptorName = acceptorProfile?.basicInfo?.fullName || 'Someone';
    const accParts = acceptorName.trim().split(' ');
    if (accParts.length > 1) {
      acceptorName = `${accParts[0]} ${accParts[accParts.length - 1][0]}.`;
    }

    await Notification.create({
      recipientId: interest.senderId,
      senderId: receiverId,
      type: 'interest_accepted',
      title: 'Connection Successful! 🎉',
      body: `${acceptorName} accepted your interest request! You are now connected.`,
      deepLink: `/chat/${conversation._id}`,
    });

    return ApiResponse.success(
      res,
      'Connection successful! You are now connected and can chat.',
      {
        interest,
        conversationId: conversation._id,
        partnerName: senderName,
        partnerUserId: interest.senderId,
        partnerPhotoUrl: senderProfile?.photos?.find((ph: any) => ph.isPrimary)?.secureUrl || senderProfile?.photos?.[0]?.secureUrl || null,
      }
    );
  } catch (error) {
    next(error);
  }
};

/**
 * Declines a received interest
 */
export const declineInterest = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const receiverId = req.user!._id;
    const { interestId } = req.params;

    const interest = await Interest.findOne({
      _id: interestId,
      receiverId,
      status: 'pending',
    });

    if (!interest) {
      throw ApiError.notFound('Pending interest request not found');
    }

    interest.status = 'declined';
    await interest.save();

    return ApiResponse.success(res, 'Interest declined', interest);
  } catch (error) {
    next(error);
  }
};

/**
 * Withdraws a sent interest
 */
export const withdrawInterest = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const senderId = req.user!._id;
    const { interestId } = req.params;

    const interest = await Interest.findOne({
      _id: interestId,
      senderId,
      status: 'pending',
    });

    if (!interest) {
      throw ApiError.notFound('Pending interest request not found');
    }

    interest.status = 'withdrawn';
    await interest.save();

    return ApiResponse.success(res, 'Interest withdrawn', interest);
  } catch (error) {
    next(error);
  }
};

/**
 * Lists interests by type (received | sent | accepted | declined)
 */
export const getInterests = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const type = (req.query.type as string) || 'received';

    let query: any = {};

    if (type === 'received') {
      query = { receiverId: userId, status: 'pending' };
    } else if (type === 'sent') {
      query = { senderId: userId, status: 'pending' };
    } else if (type === 'accepted') {
      query = {
        $or: [
          { senderId: userId, status: 'accepted' },
          { receiverId: userId, status: 'accepted' },
        ],
      };
    } else if (type === 'declined') {
      query = {
        $or: [
          { senderId: userId, status: 'declined' },
          { receiverId: userId, status: 'declined' },
        ],
      };
    }

    const interests = await Interest.find(query).sort({ updatedAt: -1 }).lean();

    // Populate user profile details for each item
    const formattedInterests = await Promise.all(
      interests.map(async (item) => {
        const otherUserId = item.senderId.toString() === userId.toString() ? item.receiverId : item.senderId;

        const profile = await Profile.findOne({ userId: otherUserId }).lean();
        let name = profile?.basicInfo?.fullName || 'Member';
        const parts = name.trim().split(' ');
        if (parts.length > 1) {
          name = `${parts[0]} ${parts[parts.length - 1][0]}.`;
        }

        const age = profile?.basicInfo?.dateOfBirth
          ? Math.floor((Date.now() - new Date(profile.basicInfo.dateOfBirth).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
          : 24;

        // Find existing conversation ID if accepted
        let conversationId = null;
        if (item.status === 'accepted') {
          const conv = await Conversation.findOne({
            participants: { $all: [userId, otherUserId] },
          }).select('_id');
          if (conv) conversationId = conv._id;
        }

        return {
          interestId: item._id,
          status: item.status,
          isSender: item.senderId.toString() === userId.toString(),
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          conversationId,
          targetUser: {
            userId: otherUserId,
            name,
            age,
            gender: profile?.basicInfo?.gender,
            city: profile?.basicInfo?.city || 'Unknown',
            education: profile?.educationCareer?.highestEducation || 'N/A',
            occupation: profile?.educationCareer?.jobTitle || profile?.educationCareer?.occupationType || 'N/A',
            primaryPhotoUrl: profile?.photos?.find((ph: any) => ph.isPrimary)?.secureUrl || profile?.photos?.[0]?.secureUrl || null,
          },
        };
      })
    );

    return ApiResponse.success(res, `Interests list (${type}) retrieved`, formattedInterests);
  } catch (error) {
    next(error);
  }
};

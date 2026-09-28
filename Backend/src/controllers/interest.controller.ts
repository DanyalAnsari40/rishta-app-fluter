import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Interest } from '../models/interest.model';
import { Block } from '../models/block.model';
import { User } from '../models/user.model';
import { Profile } from '../models/profile.model';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';

/**
 * Sends an interest to a target user
 */
export const sendInterest = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const senderId = req.user!._id;
    const { targetUserId } = req.body;

    if (senderId.toString() === targetUserId) {
      throw ApiError.badRequest('You cannot send an interest to yourself');
    }

    if (!req.user!.emailVerified) {
      throw ApiError.forbidden('Please verify your email address before sending interests');
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

    if (interest) {
      if (interest.status === 'pending') {
        throw ApiError.conflict('An interest is already pending between you and this user');
      }
      if (interest.status === 'accepted') {
        throw ApiError.conflict('You have already accepted interest with this user');
      }
    }

    interest = await Interest.create({
      senderId,
      receiverId: targetUserId,
      status: 'pending',
    });

    return ApiResponse.success(res, 'Interest sent successfully', interest, 201);
  } catch (error) {
    next(error);
  }
};

/**
 * Accepts a received interest
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

    return ApiResponse.success(
      res,
      'Interest accepted! You can now chat with this profile.',
      interest
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
    const type = (req.query.type as string) || 'received'; // received | sent | accepted | declined

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

        return {
          interestId: item._id,
          status: item.status,
          isSender: item.senderId.toString() === userId.toString(),
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
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

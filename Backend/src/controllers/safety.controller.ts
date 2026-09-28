import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Block } from '../models/block.model';
import { Report } from '../models/report.model';
import { Profile } from '../models/profile.model';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';

export const blockUser = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const blockerId = req.user!._id;
    const { targetUserId, reason } = req.body;

    if (blockerId.toString() === targetUserId) {
      throw ApiError.badRequest('You cannot block yourself');
    }

    const existing = await Block.findOne({ blockerId, blockedId: targetUserId });
    if (existing) {
      return ApiResponse.success(res, 'User is already blocked', existing);
    }

    const block = await Block.create({ blockerId, blockedId: targetUserId, reason });
    return ApiResponse.success(res, 'User blocked successfully', block, 201);
  } catch (error) {
    next(error);
  }
};

export const unblockUser = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const blockerId = req.user!._id;
    const { targetUserId } = req.params;

    await Block.deleteOne({ blockerId, blockedId: targetUserId });
    return ApiResponse.success(res, 'User unblocked successfully');
  } catch (error) {
    next(error);
  }
};

export const getBlockedUsers = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const blockerId = req.user!._id;

    const blocks = await Block.find({ blockerId }).sort({ createdAt: -1 }).lean();

    const formattedList = await Promise.all(
      blocks.map(async (b) => {
        const profile = await Profile.findOne({ userId: b.blockedId }).lean();
        let name = profile?.basicInfo?.fullName || 'Member';
        const parts = name.trim().split(' ');
        if (parts.length > 1) {
          name = `${parts[0]} ${parts[parts.length - 1][0]}.`;
        }

        return {
          blockId: b._id,
          blockedUserId: b.blockedId,
          reason: b.reason,
          createdAt: b.createdAt,
          name,
          primaryPhotoUrl: profile?.photos?.find((ph: any) => ph.isPrimary)?.secureUrl || profile?.photos?.[0]?.secureUrl || null,
        };
      })
    );

    return ApiResponse.success(res, 'Blocked users list retrieved', formattedList);
  } catch (error) {
    next(error);
  }
};

export const reportUser = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const reporterId = req.user!._id;
    const { targetUserId, reason, details } = req.body;

    if (reporterId.toString() === targetUserId) {
      throw ApiError.badRequest('You cannot report yourself');
    }

    const report = await Report.create({
      reporterId,
      reportedId: targetUserId,
      reason,
      details,
      status: 'pending',
    });

    // Check if target user has received multiple reports (auto-flag threshold)
    const reportCount = await Report.countDocuments({ reportedId: targetUserId, status: 'pending' });
    if (reportCount >= 3) {
      // Temporarily pause profile until admin reviews
      await Profile.findOneAndUpdate({ userId: targetUserId }, { 'privacySettings.isPaused': true });
    }

    return ApiResponse.success(
      res,
      'Report submitted successfully. Our admin team will review it shortly.',
      report,
      201
    );
  } catch (error) {
    next(error);
  }
};

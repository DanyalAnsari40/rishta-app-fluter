import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Shortlist } from '../models/shortlist.model';
import { Profile } from '../models/profile.model';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';

export const addShortlist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { targetUserId } = req.body;

    if (userId.toString() === targetUserId) {
      throw ApiError.badRequest('You cannot shortlist your own profile');
    }

    const existing = await Shortlist.findOne({ userId, targetUserId });
    if (existing) {
      return ApiResponse.success(res, 'Profile is already shortlisted', existing);
    }

    const shortlist = await Shortlist.create({ userId, targetUserId });
    return ApiResponse.success(res, 'Profile added to shortlist', shortlist, 201);
  } catch (error) {
    next(error);
  }
};

export const removeShortlist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { targetUserId } = req.params;

    await Shortlist.deleteOne({ userId, targetUserId });
    return ApiResponse.success(res, 'Profile removed from shortlist');
  } catch (error) {
    next(error);
  }
};

export const getShortlist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;

    const items = await Shortlist.find({ userId }).sort({ createdAt: -1 }).lean();

    const formattedList = await Promise.all(
      items.map(async (item) => {
        const profile = await Profile.findOne({ userId: item.targetUserId }).lean();
        let name = profile?.basicInfo?.fullName || 'Member';
        const parts = name.trim().split(' ');
        if (parts.length > 1) {
          name = `${parts[0]} ${parts[parts.length - 1][0]}.`;
        }

        const age = profile?.basicInfo?.dateOfBirth
          ? Math.floor((Date.now() - new Date(profile.basicInfo.dateOfBirth).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
          : 24;

        return {
          shortlistId: item._id,
          targetUserId: item.targetUserId,
          createdAt: item.createdAt,
          profile: {
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

    return ApiResponse.success(res, 'Shortlist retrieved successfully', formattedList);
  } catch (error) {
    next(error);
  }
};

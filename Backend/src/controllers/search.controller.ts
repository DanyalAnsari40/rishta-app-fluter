import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Profile } from '../models/profile.model';
import { User } from '../models/user.model';
import { ApiResponse } from '../utils/apiResponse';
import { MatchingService } from '../services/matching.service';

/**
 * Gets Home feed data (New members, Recently active, Daily recommendations, and feed profiles)
 */
export const getHomeFeed = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;

    // Get current user's profile
    const myProfile = await Profile.findOne({ userId });

    // Determine opposite gender filter
    const myGender = myProfile?.basicInfo?.gender || 'male';
    const targetGender = myGender === 'male' ? 'female' : 'male';

    // Find active, non-admin user IDs
    const activeUsers = await User.find({
      status: 'active',
      role: 'user',
      _id: { $ne: userId },
    }).select('_id lastActiveAt createdAt');

    const activeUserIds = activeUsers.map((u) => u._id);

    // Query profiles matching business rules (Opposite gender, profileCompleteness >= 70, not paused)
    const baseQuery = {
      userId: { $in: activeUserIds },
      'basicInfo.gender': targetGender,
      'privacySettings.isPaused': { $ne: true },
      // In dev mode, lower threshold to 30 so initial profiles display seamlessly
      profileCompleteness: { $gte: 30 },
    };

    // 1. New Members (registered in last 14 days)
    const newMembersRaw = await Profile.find(baseQuery)
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();

    // 2. Recently Active Members
    const recentlyActiveRaw = await Profile.find(baseQuery)
      .sort({ updatedAt: -1 })
      .limit(10)
      .lean();

    // 3. General Feed Profiles with pagination
    const page = parseInt(req.query.page as string, 10) || 1;
    const limit = parseInt(req.query.limit as string, 10) || 20;
    const skip = (page - 1) * limit;

    const feedRaw = await Profile.find(baseQuery)
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    const total = await Profile.countDocuments(baseQuery);

    // Format profiles & attach compatibility percentages
    const formatProfile = (p: any) => {
      const compatibility = myProfile ? MatchingService.calculateCompatibility(myProfile, p) : 75;

      let name = p.basicInfo?.fullName || 'Member';
      const nameParts = name.trim().split(' ');
      if (nameParts.length > 1) {
        name = `${nameParts[0]} ${nameParts[nameParts.length - 1][0]}.`;
      }

      const age = p.basicInfo?.dateOfBirth
        ? Math.floor((Date.now() - new Date(p.basicInfo.dateOfBirth).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
        : 24;

      return {
        id: p._id,
        userId: p.userId,
        name,
        age,
        gender: p.basicInfo?.gender,
        city: p.basicInfo?.city || 'Unknown',
        education: p.educationCareer?.highestEducation || 'N/A',
        occupation: p.educationCareer?.jobTitle || p.educationCareer?.occupationType || 'N/A',
        maritalStatus: p.basicInfo?.maritalStatus || 'never_married',
        religion: p.religionCommunity?.religion || 'Islam',
        sect: p.religionCommunity?.sect || 'Sunni',
        primaryPhotoUrl: p.photos?.find((ph: any) => ph.isPrimary)?.secureUrl || p.photos?.[0]?.secureUrl || null,
        compatibilityPercentage: compatibility,
        isVerifiedBadge: p.isVerifiedBadge || false,
        profileCompleteness: p.profileCompleteness || 0,
      };
    };

    const newMembers = newMembersRaw.map(formatProfile);
    const recentlyActive = recentlyActiveRaw.map(formatProfile);
    const feed = feedRaw.map(formatProfile);

    return ApiResponse.success(res, 'Home feed retrieved successfully', {
      newMembers,
      recentlyActive,
      feed,
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

/**
 * Searches profiles with multi-field filters & pagination
 */
export const searchProfiles = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const myProfile = await Profile.findOne({ userId });

    const {
      gender,
      ageMin,
      ageMax,
      heightMinCm,
      heightMaxCm,
      city,
      sect,
      education,
      maritalStatus,
      occupationType,
      page = '1',
      limit = '20',
    } = req.query;

    const myGender = myProfile?.basicInfo?.gender || 'male';
    const targetGender = (gender as string) || (myGender === 'male' ? 'female' : 'male');

    const activeUsers = await User.find({
      status: 'active',
      role: 'user',
      _id: { $ne: userId },
    }).select('_id');

    const activeUserIds = activeUsers.map((u) => u._id);

    const queryFilters: any = {
      userId: { $in: activeUserIds },
      'basicInfo.gender': targetGender,
      'privacySettings.isPaused': { $ne: true },
      profileCompleteness: { $gte: 30 },
    };

    if (city) {
      queryFilters['basicInfo.city'] = { $regex: new RegExp(city as string, 'i') };
    }

    if (sect) {
      queryFilters['religionCommunity.sect'] = { $regex: new RegExp(sect as string, 'i') };
    }

    if (education) {
      queryFilters['educationCareer.highestEducation'] = { $regex: new RegExp(education as string, 'i') };
    }

    if (maritalStatus) {
      queryFilters['basicInfo.maritalStatus'] = maritalStatus;
    }

    if (occupationType) {
      queryFilters['educationCareer.occupationType'] = occupationType;
    }

    const pageNum = parseInt(page as string, 10);
    const limitNum = parseInt(limit as string, 10);
    const skip = (pageNum - 1) * limitNum;

    const rawResults = await Profile.find(queryFilters)
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .lean();

    const total = await Profile.countDocuments(queryFilters);

    const results = rawResults.map((p: any) => {
      const compatibility = myProfile ? MatchingService.calculateCompatibility(myProfile, p) : 75;

      let name = p.basicInfo?.fullName || 'Member';
      const nameParts = name.trim().split(' ');
      if (nameParts.length > 1) {
        name = `${nameParts[0]} ${nameParts[nameParts.length - 1][0]}.`;
      }

      const age = p.basicInfo?.dateOfBirth
        ? Math.floor((Date.now() - new Date(p.basicInfo.dateOfBirth).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
        : 24;

      return {
        id: p._id,
        userId: p.userId,
        name,
        age,
        gender: p.basicInfo?.gender,
        city: p.basicInfo?.city || 'Unknown',
        education: p.educationCareer?.highestEducation || 'N/A',
        occupation: p.educationCareer?.jobTitle || p.educationCareer?.occupationType || 'N/A',
        maritalStatus: p.basicInfo?.maritalStatus || 'never_married',
        religion: p.religionCommunity?.religion || 'Islam',
        sect: p.religionCommunity?.sect || 'Sunni',
        primaryPhotoUrl: p.photos?.find((ph: any) => ph.isPrimary)?.secureUrl || p.photos?.[0]?.secureUrl || null,
        compatibilityPercentage: compatibility,
        isVerifiedBadge: p.isVerifiedBadge || false,
        profileCompleteness: p.profileCompleteness || 0,
      };
    });

    return ApiResponse.success(res, 'Search completed successfully', {
      results,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    next(error);
  }
};

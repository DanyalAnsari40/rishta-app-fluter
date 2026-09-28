import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { Profile, calculateProfileCompleteness } from '../models/profile.model';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';
import { CloudinaryService } from '../services/cloudinary.service';

/**
 * Gets or initializes the current user's profile
 */
export const getProfileMe = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;

    let profile = await Profile.findOne({ userId });

    if (!profile) {
      profile = await Profile.create({
        userId,
        photos: [],
        privacySettings: {
          photoVisibility: 'everyone',
          phoneVisibility: 'mutual_accept_only',
          isPaused: false,
          hideLastSeen: false,
        },
        profileCompleteness: 0,
      });
    }

    return ApiResponse.success(res, 'Profile retrieved successfully', profile);
  } catch (error) {
    next(error);
  }
};

/**
 * Updates a specific section of the profile (save-as-you-go wizard)
 */
export const updateProfileSection = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const userId = req.user!._id;
    const { section } = req.params; // 'basic-info', 'religion-community', 'education-career', 'family-details', 'lifestyle-about', 'partner-preferences', 'privacy-settings'

    let profile = await Profile.findOne({ userId });
    if (!profile) {
      profile = new Profile({ userId, photos: [] });
    }

    const payload = req.body;

    switch (section) {
      case 'basic-info':
        profile.basicInfo = {
          ...profile.basicInfo,
          ...payload,
          dateOfBirth: new Date(payload.dateOfBirth),
        };
        break;
      case 'religion-community':
        profile.religionCommunity = { ...profile.religionCommunity, ...payload };
        break;
      case 'education-career':
        profile.educationCareer = { ...profile.educationCareer, ...payload };
        break;
      case 'family-details':
        profile.familyDetails = { ...profile.familyDetails, ...payload };
        break;
      case 'lifestyle-about':
        profile.lifestyleAbout = { ...profile.lifestyleAbout, ...payload };
        break;
      case 'partner-preferences':
        profile.partnerPreferences = { ...profile.partnerPreferences, ...payload };
        break;
      case 'privacy-settings':
        profile.privacySettings = { ...profile.privacySettings, ...payload };
        break;
      default:
        throw ApiError.badRequest(`Invalid section name: ${section}`);
    }

    // Recalculate profile completeness score
    profile.profileCompleteness = calculateProfileCompleteness(profile);
    await profile.save();

    return ApiResponse.success(
      res,
      `Section '${section}' updated successfully`,
      profile
    );
  } catch (error) {
    next(error);
  }
};

/**
 * Generates signed Cloudinary upload signature for client-side photo upload
 */
export const getPhotoSignature = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const userId = req.user!._id.toString();
    const type = req.query.type === 'verification' ? 'verification' : 'photos';

    const signatureData = CloudinaryService.generateUploadSignature(userId, type);

    return ApiResponse.success(res, 'Upload signature generated successfully', signatureData);
  } catch (error) {
    next(error);
  }
};

/**
 * Adds an uploaded photo object to the profile
 */
export const addPhoto = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { publicId, secureUrl, width, height, isPrimary } = req.body;

    let profile = await Profile.findOne({ userId });
    if (!profile) {
      profile = await Profile.create({ userId, photos: [] });
    }

    if (profile.photos.length >= 6) {
      throw ApiError.badRequest('Maximum limit of 6 photos reached');
    }

    const setPrimary = isPrimary || profile.photos.length === 0;

    if (setPrimary) {
      profile.photos.forEach((p) => (p.isPrimary = false));
    }

    profile.photos.push({
      publicId,
      secureUrl,
      width,
      height,
      isPrimary: setPrimary,
      isApproved: false, // New photo enters admin moderation queue
      uploadedAt: new Date(),
    } as any);

    profile.profileCompleteness = calculateProfileCompleteness(profile);
    await profile.save();

    return ApiResponse.success(res, 'Photo added successfully', profile.photos);
  } catch (error) {
    next(error);
  }
};

/**
 * Deletes a photo by publicId
 */
export const deletePhoto = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { publicId } = req.params;

    const profile = await Profile.findOne({ userId });
    if (!profile) {
      throw ApiError.notFound('Profile not found');
    }

    const photoIndex = profile.photos.findIndex((p) => p.publicId === publicId);
    if (photoIndex === -1) {
      throw ApiError.notFound('Photo not found in your profile');
    }

    const wasPrimary = profile.photos[photoIndex].isPrimary;
    profile.photos.splice(photoIndex, 1);

    if (wasPrimary && profile.photos.length > 0) {
      profile.photos[0].isPrimary = true;
    }

    profile.profileCompleteness = calculateProfileCompleteness(profile);
    await profile.save();

    // Asynchronously delete asset from Cloudinary
    CloudinaryService.deleteAsset(publicId as string);

    return ApiResponse.success(res, 'Photo deleted successfully', profile.photos);
  } catch (error) {
    next(error);
  }
};

/**
 * Sets primary photo
 */
export const setPrimaryPhoto = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;
    const { publicId } = req.body;

    const profile = await Profile.findOne({ userId });
    if (!profile) {
      throw ApiError.notFound('Profile not found');
    }

    let found = false;
    profile.photos.forEach((p) => {
      if (p.publicId === publicId) {
        p.isPrimary = true;
        found = true;
      } else {
        p.isPrimary = false;
      }
    });

    if (!found) {
      throw ApiError.notFound('Photo not found in profile');
    }

    await profile.save();

    return ApiResponse.success(res, 'Primary photo updated', profile.photos);
  } catch (error) {
    next(error);
  }
};

/**
 * Gets a public profile by ID with privacy protection (First Name + Last Initial for non-matched)
 */
export const getPublicProfileById = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const targetUserId = req.params.id;

    const profile = await Profile.findOne({ userId: targetUserId }).populate('userId', 'email status');

    if (!profile || (profile.userId as any)?.status !== 'active') {
      throw ApiError.notFound('Profile not found or no longer active');
    }

    if (profile.privacySettings.isPaused) {
      throw ApiError.notFound('This profile is temporarily hidden by the user');
    }

    // Format full name to First Name + Initial for non-matched users
    const publicProfile = profile.toObject();
    if (publicProfile.basicInfo?.fullName) {
      const parts = publicProfile.basicInfo.fullName.trim().split(' ');
      if (parts.length > 1) {
        publicProfile.basicInfo.fullName = `${parts[0]} ${parts[parts.length - 1][0]}.`;
      }
    }

    // Remove private fields
    if (publicProfile.familyDetails) {
      delete publicProfile.familyDetails.guardianName;
      delete publicProfile.familyDetails.guardianPhone;
    }

    if (publicProfile.educationCareer && !publicProfile.educationCareer.showIncomePublicly) {
      delete publicProfile.educationCareer.monthlyIncomeRange;
    }

    return ApiResponse.success(res, 'Public profile retrieved successfully', publicProfile);
  } catch (error) {
    next(error);
  }
};

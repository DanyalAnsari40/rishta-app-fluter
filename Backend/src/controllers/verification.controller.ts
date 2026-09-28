import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { VerificationRequest } from '../models/verificationRequest.model';
import { Profile } from '../models/profile.model';
import { ApiError } from '../utils/apiError';

export class VerificationController {
  /**
   * Submit selfie and ID card photo for badge verification
   */
  static async submitVerification(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!._id;
      const { selfieUrl, idCardUrl } = req.body;

      if (!selfieUrl || !idCardUrl) {
        return next(ApiError.badRequest('Both selfieUrl and idCardUrl are required'));
      }

      // Check existing pending request
      const existingPending = await VerificationRequest.findOne({
        userId,
        status: 'pending',
      });

      if (existingPending) {
        return next(ApiError.badRequest('You already have a pending verification request in review'));
      }

      const request = await VerificationRequest.create({
        userId,
        selfieUrl,
        idCardUrl,
        status: 'pending',
      });

      res.status(201).json({
        success: true,
        message: 'Verification request submitted successfully. Our team will review it within 24-48 hours.',
        data: request,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get current user's verification status
   */
  static async getVerificationStatus(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!._id;

      const profile = await Profile.findOne({ userId });
      const isVerified = profile?.isVerifiedBadge || false;

      const latestRequest = await VerificationRequest.findOne({ userId }).sort({ createdAt: -1 });

      res.status(200).json({
        success: true,
        data: {
          isVerifiedBadge: isVerified,
          latestRequest: latestRequest
            ? {
                id: latestRequest._id,
                status: latestRequest.status,
                rejectionReason: latestRequest.rejectionReason,
                submittedAt: latestRequest.createdAt,
              }
            : null,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}

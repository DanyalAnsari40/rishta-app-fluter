import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { User } from '../models/user.model';
import { Profile } from '../models/profile.model';
import { Report } from '../models/report.model';
import { VerificationRequest } from '../models/verificationRequest.model';
import { AuditLog } from '../models/auditLog.model';
import { RefreshToken } from '../models/refreshToken.model';
import { NotificationService } from '../services/notification.service';
import { ApiError } from '../utils/apiError';

export class AdminController {
  /**
   * Admin Dashboard Metrics & Quick Stats
   */
  static async getDashboardStats(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const startOfToday = new Date();
      startOfToday.setHours(0, 0, 0, 0);

      const [
        totalUsers,
        activeToday,
        pendingReports,
        pendingVerifications,
        maleCount,
        femaleCount,
      ] = await Promise.all([
        User.countDocuments({ status: { $ne: 'deleted' } }),
        User.countDocuments({ lastActiveAt: { $gte: startOfToday }, status: { $ne: 'deleted' } }),
        Report.countDocuments({ status: 'pending' }),
        VerificationRequest.countDocuments({ status: 'pending' }),
        Profile.countDocuments({ 'basicInfo.gender': 'male' }),
        Profile.countDocuments({ 'basicInfo.gender': 'female' }),
      ]);

      // Count unapproved photos
      const pendingPhotosProfiles = await Profile.find({ 'photos.isApproved': false });
      let pendingPhotosCount = 0;
      pendingPhotosProfiles.forEach((p) => {
        pendingPhotosCount += p.photos.filter((ph) => !ph.isApproved).length;
      });

      res.status(200).json({
        success: true,
        data: {
          totalUsers,
          activeToday,
          openReportsCount: pendingReports,
          pendingVerificationsCount: pendingVerifications,
          pendingPhotosCount,
          genderSplit: {
            male: maleCount,
            female: femaleCount,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get paginated user management list with search & filters
   */
  static async getUsers(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const skip = (page - 1) * limit;

      const { search, gender, status, isVerified } = req.query;

      const query: any = { status: { $ne: 'deleted' } };
      if (status) query.status = status;

      // Search by email or profile name
      if (search) {
        query.$or = [{ email: { $regex: search, $options: 'i' } }];
      }

      const [users, total] = await Promise.all([
        User.find(query).sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        User.countDocuments(query),
      ]);

      // Fetch profiles for users
      const userIds = users.map((u) => u._id);
      const profileQuery: any = { userId: { $in: userIds } };
      if (gender) profileQuery['basicInfo.gender'] = gender;
      if (isVerified !== undefined) profileQuery.isVerifiedBadge = isVerified === 'true';

      const profiles = await Profile.find(profileQuery).lean();
      const profileMap = new Map(profiles.map((p) => [p.userId.toString(), p]));

      const combined = users
        .map((u) => {
          const profile = profileMap.get(u._id.toString());
          if (gender && (!profile || profile.basicInfo?.gender !== gender)) return null;
          if (isVerified !== undefined && (!profile || profile.isVerifiedBadge !== (isVerified === 'true'))) return null;
          return {
            ...u,
            profile: profile || null,
          };
        })
        .filter(Boolean);

      res.status(200).json({
        success: true,
        data: {
          users: combined,
          pagination: {
            total,
            page,
            limit,
            pages: Math.ceil(total / limit),
          },
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get complete user details (Profile + User + Verification History)
   */
  static async getUserDetails(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const user = await User.findById(id).lean();
      if (!user) return next(ApiError.notFound('User not found'));

      const profile = await Profile.findOne({ userId: id }).lean();
      const verifications = await VerificationRequest.find({ userId: id }).sort({ createdAt: -1 }).lean();
      const auditLogs = await AuditLog.find({ 'details.targetUserId': id }).sort({ createdAt: -1 }).limit(20).lean();

      res.status(200).json({
        success: true,
        data: {
          user,
          profile,
          verifications,
          auditLogs,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Suspend / Unsuspend User Account
   */
  static async suspendUser(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { suspend, reason } = req.body;

      const user = await User.findById(id);
      if (!user) return next(ApiError.notFound('User not found'));

      user.status = suspend ? 'suspended' : 'active';
      await user.save();

      if (suspend) {
        // Revoke refresh tokens on suspension
        await RefreshToken.deleteMany({ userId: id });
      }

      await AuditLog.create({
        adminId: req.user!._id,
        action: suspend ? 'SUSPEND_USER' : 'UNSUSPEND_USER',
        details: { targetUserId: id, reason: reason || 'Admin action' },
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: `User ${suspend ? 'suspended' : 'unsuspended'} successfully`,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Toggle Verified Badge for User Profile
   */
  static async verifyUser(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { isVerified } = req.body;

      const profile = await Profile.findOne({ userId: id });
      if (!profile) return next(ApiError.notFound('Profile not found for this user'));

      profile.isVerifiedBadge = Boolean(isVerified);
      await profile.save();

      await AuditLog.create({
        adminId: req.user!._id,
        action: isVerified ? 'VERIFY_USER_BADGE' : 'UNVERIFY_USER_BADGE',
        details: { targetUserId: id },
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: `User verified badge ${isVerified ? 'granted' : 'revoked'}`,
        data: profile,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete User Account (Soft delete)
   */
  static async deleteUser(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const user = await User.findById(id);
      if (!user) return next(ApiError.notFound('User not found'));

      user.status = 'deleted';
      await user.save();
      await RefreshToken.deleteMany({ userId: id });

      await AuditLog.create({
        adminId: req.user!._id,
        action: 'DELETE_USER',
        details: { targetUserId: id },
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: 'User account deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Force Logout User (Revoke refresh tokens)
   */
  static async forceLogout(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      await RefreshToken.deleteMany({ userId: id });

      await AuditLog.create({
        adminId: req.user!._id,
        action: 'FORCE_LOGOUT_USER',
        details: { targetUserId: id },
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: 'User sessions invalidated successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Pending Photos Moderation Queue
   */
  static async getPendingPhotos(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const profiles = await Profile.find({ 'photos.isApproved': false })
        .populate('userId', 'email profileCreatedFor')
        .lean();

      const pendingItems: any[] = [];
      profiles.forEach((p: any) => {
        p.photos.forEach((photo: any) => {
          if (!photo.isApproved) {
            pendingItems.push({
              profileId: p._id,
              userId: p.userId,
              fullName: p.basicInfo?.fullName || 'User',
              photo,
            });
          }
        });
      });

      res.status(200).json({
        success: true,
        data: pendingItems,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Approve or Reject a photo
   */
  static async reviewPhoto(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { profileId, publicId, action } = req.body; // action: 'approve' | 'reject'

      const profile = await Profile.findById(profileId);
      if (!profile) return next(ApiError.notFound('Profile not found'));

      const photoIndex = profile.photos.findIndex((p) => p.publicId === publicId);
      if (photoIndex === -1) return next(ApiError.notFound('Photo not found in profile'));

      if (action === 'approve') {
        profile.photos[photoIndex].isApproved = true;
      } else {
        profile.photos.splice(photoIndex, 1);
      }

      await profile.save();

      await AuditLog.create({
        adminId: req.user!._id,
        action: action === 'approve' ? 'APPROVE_PHOTO' : 'REJECT_PHOTO',
        details: { profileId, publicId },
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: `Photo ${action}d successfully`,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Reports Moderation Queue
   */
  static async getReports(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const skip = (page - 1) * limit;

      const status = (req.query.status as string) || 'pending';

      const [reports, total] = await Promise.all([
        Report.find({ status })
          .populate('reporterId', 'email')
          .populate('reportedId', 'email')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit)
          .lean(),
        Report.countDocuments({ status }),
      ]);

      res.status(200).json({
        success: true,
        data: {
          reports,
          pagination: { total, page, limit, pages: Math.ceil(total / limit) },
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Action Report (Dismiss, Warn, Suspend, Delete)
   */
  static async reviewReport(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { action, resolutionNotes } = req.body; // action: 'dismiss' | 'warn' | 'suspend' | 'delete'

      const report = await Report.findById(id);
      if (!report) return next(ApiError.notFound('Report not found'));

      report.status = action === 'dismiss' ? 'dismissed' : 'action_taken';
      report.adminNotes = resolutionNotes || `Actioned by admin: ${action}`;
      await report.save();

      if (action === 'suspend') {
        await User.findByIdAndUpdate(report.reportedId, { status: 'suspended' });
        await RefreshToken.deleteMany({ userId: report.reportedId });
      } else if (action === 'delete') {
        await User.findByIdAndUpdate(report.reportedId, { status: 'deleted' });
        await RefreshToken.deleteMany({ userId: report.reportedId });
      } else if (action === 'warn') {
        await NotificationService.sendNotification({
          recipientId: report.reportedId.toString(),
          type: 'system',
          title: 'Community Warning',
          body: 'Your profile has received a safety report. Please ensure your conduct follows our guidelines.',
        });
      }

      await AuditLog.create({
        adminId: req.user!._id,
        action: 'ACTION_REPORT',
        details: { reportId: id, action, resolutionNotes },
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: `Report actioned successfully with result: ${action}`,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Pending Verification Requests
   */
  static async getVerifications(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const status = (req.query.status as string) || 'pending';

      const requests = await VerificationRequest.find({ status })
        .populate('userId', 'email profileCreatedFor')
        .sort({ createdAt: -1 })
        .lean();

      // Attach profile basic info
      const userIds = requests.map((r: any) => r.userId?._id);
      const profiles = await Profile.find({ userId: { $in: userIds } }).lean();
      const profileMap = new Map(profiles.map((p) => [p.userId.toString(), p]));

      const data = requests.map((r: any) => ({
        ...r,
        profile: r.userId ? profileMap.get(r.userId._id.toString()) || null : null,
      }));

      res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Action Verification Request (Approve or Reject)
   */
  static async reviewVerification(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const { action, rejectionReason } = req.body; // action: 'approve' | 'reject'

      const request = await VerificationRequest.findById(id);
      if (!request) return next(ApiError.notFound('Verification request not found'));

      request.status = action === 'approve' ? 'approved' : 'rejected';
      if (action === 'reject') {
        request.rejectionReason = rejectionReason || 'Information or photo could not be verified.';
      }
      request.reviewedBy = req.user!._id;
      request.reviewedAt = new Date();
      await request.save();

      if (action === 'approve') {
        await Profile.findOneAndUpdate({ userId: request.userId }, { isVerifiedBadge: true }, { upsert: true });
        await NotificationService.sendNotification({
          recipientId: request.userId.toString(),
          type: 'verification_approved',
          title: 'Verification Approved! 🎉',
          body: 'Congratulations! Your profile is now verified with the official trust badge.',
        });
      } else {
        await NotificationService.sendNotification({
          recipientId: request.userId.toString(),
          type: 'verification_rejected',
          title: 'Verification Update',
          body: `Verification could not be approved. Reason: ${request.rejectionReason}`,
        });
      }

      await AuditLog.create({
        adminId: req.user!._id,
        action: action === 'approve' ? 'APPROVE_VERIFICATION' : 'REJECT_VERIFICATION',
        details: { verificationId: id, userId: request.userId, rejectionReason },
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: `Verification request ${action}d successfully`,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Broadcast Push Notification to All Users
   */
  static async broadcastNotification(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { title, body } = req.body;
      if (!title || !body) return next(ApiError.badRequest('Title and body are required'));

      await NotificationService.broadcastNotification(title, body);

      await AuditLog.create({
        adminId: req.user!._id,
        action: 'BROADCAST_NOTIFICATION',
        details: { title, body },
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: 'Broadcast notification sent successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Admin Audit Logs List
   */
  static async getAuditLogs(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 30;
      const skip = (page - 1) * limit;

      const [logs, total] = await Promise.all([
        AuditLog.find()
          .populate('adminId', 'email')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit)
          .lean(),
        AuditLog.countDocuments(),
      ]);

      res.status(200).json({
        success: true,
        data: {
          logs,
          pagination: { total, page, limit, pages: Math.ceil(total / limit) },
        },
      });
    } catch (error) {
      next(error);
    }
  }
}

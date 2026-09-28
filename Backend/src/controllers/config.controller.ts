import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import { AppConfig } from '../models/appConfig.model';
import { AuditLog } from '../models/auditLog.model';

export class ConfigController {
  /**
   * Get public app config (min version, maintenance mode, announcement banner)
   */
  static async getConfig(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      let config = await AppConfig.findOne();
      if (!config) {
        config = await AppConfig.create({
          minSupportedVersion: '1.0.0',
          latestVersion: '1.0.0',
          maintenanceMode: false,
        });
      }

      res.status(200).json({
        success: true,
        data: config,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Admin: Update app config
   */
  static async updateConfig(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const {
        minSupportedVersion,
        latestVersion,
        maintenanceMode,
        announcementTitle,
        announcementBody,
        announcementActive,
        androidAppUrl,
        iosAppUrl,
      } = req.body;

      let config = await AppConfig.findOne();
      if (!config) {
        config = new AppConfig();
      }

      if (minSupportedVersion !== undefined) config.minSupportedVersion = minSupportedVersion;
      if (latestVersion !== undefined) config.latestVersion = latestVersion;
      if (maintenanceMode !== undefined) config.maintenanceMode = maintenanceMode;
      if (announcementTitle !== undefined) config.announcementTitle = announcementTitle;
      if (announcementBody !== undefined) config.announcementBody = announcementBody;
      if (announcementActive !== undefined) config.announcementActive = announcementActive;
      if (androidAppUrl !== undefined) config.androidAppUrl = androidAppUrl;
      if (iosAppUrl !== undefined) config.iosAppUrl = iosAppUrl;

      await config.save();

      await AuditLog.create({
        adminId: req.user!._id,
        action: 'UPDATE_APP_CONFIG',
        details: req.body,
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: 'App configuration updated successfully',
        data: config,
      });
    } catch (error) {
      next(error);
    }
  }
}

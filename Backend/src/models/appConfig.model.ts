import mongoose, { Schema, Document } from 'mongoose';

export interface IAppConfig extends Document {
  minSupportedVersion: string;
  latestVersion: string;
  maintenanceMode: boolean;
  announcementTitle?: string;
  announcementBody?: string;
  announcementActive: boolean;
  androidAppUrl?: string;
  iosAppUrl?: string;
  updatedAt: Date;
}

const appConfigSchema = new Schema<IAppConfig>(
  {
    minSupportedVersion: {
      type: String,
      default: '1.0.0',
    },
    latestVersion: {
      type: String,
      default: '1.0.0',
    },
    maintenanceMode: {
      type: Boolean,
      default: false,
    },
    announcementTitle: {
      type: String,
    },
    announcementBody: {
      type: String,
    },
    announcementActive: {
      type: Boolean,
      default: false,
    },
    androidAppUrl: {
      type: String,
      default: 'https://play.google.com/store/apps/details?id=com.rishta.app',
    },
    iosAppUrl: {
      type: String,
      default: 'https://apps.apple.com/app/id6400000000',
    },
  },
  {
    timestamps: true,
  }
);

export const AppConfig = mongoose.model<IAppConfig>('AppConfig', appConfigSchema);

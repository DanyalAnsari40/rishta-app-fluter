import { v2 as cloudinary } from 'cloudinary';
import { env } from './env';
import { logger } from '../utils/logger';

export const initCloudinary = (): void => {
  if (env.CLOUDINARY_CLOUD_NAME && env.CLOUDINARY_API_KEY && env.CLOUDINARY_API_SECRET) {
    cloudinary.config({
      cloud_name: env.CLOUDINARY_CLOUD_NAME,
      api_key: env.CLOUDINARY_API_KEY,
      api_secret: env.CLOUDINARY_API_SECRET,
      secure: true,
    });
    logger.info('☁️ Cloudinary initialized successfully');
  } else {
    logger.warn('⚠️ Cloudinary environment variables missing. Cloud uploads will use mock/stub mode.');
  }
};

export { cloudinary };

import { cloudinary } from '../config/cloudinary';
import { env } from '../config/env';

export class CloudinaryService {
  /**
   * Generates a signed upload signature for direct client-side upload to Cloudinary.
   */
  static generateUploadSignature(userId: string, folderType: 'photos' | 'verification' = 'photos') {
    const timestamp = Math.round(new Date().getTime() / 1000);
    const folder =
      folderType === 'verification'
        ? `rishta/verification/${userId}`
        : `rishta/users/${userId}/photos`;

    const type = folderType === 'verification' ? 'authenticated' : 'upload';

    const paramsToSign: Record<string, any> = {
      timestamp,
      folder,
      type,
    };

    const signature = cloudinary.utils.api_sign_request(
      paramsToSign,
      env.CLOUDINARY_API_SECRET
    );

    return {
      signature,
      timestamp,
      folder,
      type,
      apiKey: env.CLOUDINARY_API_KEY,
      cloudName: env.CLOUDINARY_CLOUD_NAME,
    };
  }

  /**
   * Deletes an asset by publicId from Cloudinary.
   */
  static async deleteAsset(publicId: string, resourceType: string = 'image'): Promise<boolean> {
    try {
      if (!env.CLOUDINARY_API_SECRET) return true;
      const result = await cloudinary.uploader.destroy(publicId, {
        resource_type: resourceType,
        invalidate: true,
      });
      return result.result === 'ok';
    } catch (error) {
      console.error(`Failed to delete Cloudinary asset ${publicId}:`, error);
      return false;
    }
  }
}

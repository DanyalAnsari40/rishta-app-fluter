import { Router } from 'express';
import {
  getProfileMe,
  updateProfileSection,
  getPhotoSignature,
  addPhoto,
  deletePhoto,
  setPrimaryPhoto,
  getPublicProfileById,
} from '../controllers/profile.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validate } from '../middleware/validate.middleware';
import {
  addPhotoSchema,
} from '../validations/profile.validation';

const router = Router();

// Protect all profile routes with authentication
router.use(authenticate);

router.get('/me', getProfileMe);
router.put('/section/:section', updateProfileSection);

// Photo management endpoints
router.get('/photo-signature', getPhotoSignature);
router.post('/photos', validate(addPhotoSchema), addPhoto);
router.delete('/photos/:publicId', deletePhoto);
router.put('/photos/primary', setPrimaryPhoto);

// Public profile retrieval by user ID
router.get('/:id', getPublicProfileById);

export default router;

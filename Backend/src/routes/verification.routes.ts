import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { VerificationController } from '../controllers/verification.controller';

const router = Router();

router.use(authenticate);

router.post('/submit', VerificationController.submitVerification);
router.get('/status', VerificationController.getVerificationStatus);

export default router;

import { Router } from 'express';
import healthRoutes from './health.routes';
import authRoutes from './auth.routes';
import profileRoutes from './profile.routes';
import searchRoutes from './search.routes';
import interestRoutes from './interest.routes';
import shortlistRoutes from './shortlist.routes';
import safetyRoutes from './safety.routes';
import chatRoutes from './chat.routes';
import notificationRoutes from './notification.routes';
import verificationRoutes from './verification.routes';
import configRoutes from './config.routes';
import adminRoutes from './admin.routes';

const router = Router();

router.use('/health', healthRoutes);
router.use('/auth', authRoutes);
router.use('/profile', profileRoutes);
router.use('/search', searchRoutes);
router.use('/interests', interestRoutes);
router.use('/shortlist', shortlistRoutes);
router.use('/safety', safetyRoutes);
router.use('/chat', chatRoutes);
router.use('/notifications', notificationRoutes);
router.use('/verification', verificationRoutes);
router.use('/config', configRoutes);
router.use('/admin', adminRoutes);

export default router;


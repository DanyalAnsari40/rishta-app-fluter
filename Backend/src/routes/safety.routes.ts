import { Router } from 'express';
import { blockUser, unblockUser, getBlockedUsers, reportUser } from '../controllers/safety.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.post('/block', blockUser);
router.delete('/block/:targetUserId', unblockUser);
router.get('/block', getBlockedUsers);

router.post('/report', reportUser);

export default router;

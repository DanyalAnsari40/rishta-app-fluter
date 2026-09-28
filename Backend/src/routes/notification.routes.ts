
import { Router } from 'express';
import {
  getNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  registerDeviceToken,
} from '../controllers/notification.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

router.get('/', getNotifications);
router.put('/read-all', markAllNotificationsRead);
router.put('/:notificationId/read', markNotificationRead);
router.post('/device-token', registerDeviceToken);

export default router;

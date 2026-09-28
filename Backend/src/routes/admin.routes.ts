import { Router } from 'express';
import { authenticate, requireAdmin } from '../middleware/auth.middleware';
import { AdminController } from '../controllers/admin.controller';
import { ConfigController } from '../controllers/config.controller';

const router = Router();

router.use(authenticate, requireAdmin);

// Dashboard stats
router.get('/stats', AdminController.getDashboardStats);

// User Management
router.get('/users', AdminController.getUsers);
router.get('/users/:id', AdminController.getUserDetails);
router.patch('/users/:id/suspend', AdminController.suspendUser);
router.patch('/users/:id/verify', AdminController.verifyUser);
router.delete('/users/:id', AdminController.deleteUser);
router.post('/users/:id/force-logout', AdminController.forceLogout);

// Photo Moderation Queue
router.get('/photos/pending', AdminController.getPendingPhotos);
router.patch('/photos/review', AdminController.reviewPhoto);

// Reports Queue
router.get('/reports', AdminController.getReports);
router.patch('/reports/:id', AdminController.reviewReport);

// Verification Queue
router.get('/verifications', AdminController.getVerifications);
router.post('/verifications/:id/review', AdminController.reviewVerification);

// Broadcast Notification
router.post('/notifications/broadcast', AdminController.broadcastNotification);

// App Config Management
router.patch('/config', ConfigController.updateConfig);

// Audit Logs
router.get('/audit-logs', AdminController.getAuditLogs);

export default router;

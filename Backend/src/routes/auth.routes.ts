import { Router } from 'express';
import {
  register,
  login,
  googleLogin,
  verifyEmail,
  resendVerification,
  forgotPassword,
  resetPassword,
  getMe,
  refreshTokens,
  logout,
  deleteAccount,
  seedAdmin,
} from '../controllers/auth.controller';
import { validate } from '../middleware/validate.middleware';
import { authLimiter } from '../middleware/rateLimit.middleware';
import { authenticate } from '../middleware/auth.middleware';
import {
  registerSchema,
  loginSchema,
  googleLoginSchema,
  resendVerificationSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  refreshTokenSchema,
} from '../validations/auth.validation';

const router = Router();

router.get('/me', authenticate, getMe);
router.post('/register', authLimiter, validate(registerSchema), register);
router.post('/login', authLimiter, validate(loginSchema), login);
router.post('/google-login', authLimiter, validate(googleLoginSchema), googleLogin);

router.get('/verify-email', verifyEmail);
router.post('/verify-email', verifyEmail);
router.post('/resend-verification', authLimiter, validate(resendVerificationSchema), resendVerification);

router.post('/forgot-password', authLimiter, validate(forgotPasswordSchema), forgotPassword);
router.post('/reset-password', validate(resetPasswordSchema), resetPassword);

router.post('/refresh-token', validate(refreshTokenSchema), refreshTokens);
router.post('/logout', authenticate, logout);
router.delete('/delete-account', authenticate, deleteAccount);

// Utility route to seed admin from browser
router.get('/seed-admin', seedAdmin);

export default router;

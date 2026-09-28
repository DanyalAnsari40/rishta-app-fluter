import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import { User, IUser } from '../models/user.model';
import { EmailToken } from '../models/emailToken.model';
import { RefreshToken } from '../models/refreshToken.model';
import { ApiError } from '../utils/apiError';
import { ApiResponse } from '../utils/apiResponse';
import { EmailService } from '../services/email.service';
import {
  generateAccessToken,
  generateRefreshToken,
  generateRandomToken,
} from '../utils/token';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export const register = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email, password, phone, profileCreatedFor } = req.body;

    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      throw ApiError.conflict('An account with this email address already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    // CRITICAL SECURITY RULE: Client role payload is explicitly ignored. Always assign role: "user".
    const newUser = await User.create({
      email: email.toLowerCase(),
      password: hashedPassword,
      phone,
      profileCreatedFor: profileCreatedFor || 'self',
      role: 'user',
      status: 'active',
      emailVerified: true,
    });

    // Email verification has been disabled, users are verified by default.

    const accessToken = generateAccessToken({
      userId: newUser._id.toString(),
      role: newUser.role,
      email: newUser.email,
    });

    const refreshToken = generateRefreshToken({
      userId: newUser._id.toString(),
      role: newUser.role,
      email: newUser.email,
    });

    await RefreshToken.create({
      userId: newUser._id,
      token: refreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return ApiResponse.success(
      res,
      'Registration successful.',
      {
        user: {
          id: newUser._id,
          email: newUser.email,
          role: newUser.role,
          emailVerified: newUser.emailVerified,
          profileCreatedFor: newUser.profileCreatedFor,
        },
        accessToken,
        refreshToken,
      },
      201
    );
  } catch (error) {
    next(error);
  }
};

export const login = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
    if (!user || !user.password) {
      throw ApiError.unauthorized('Invalid email or password');
    }

    if (user.status !== 'active') {
      throw ApiError.forbidden(`Your account is ${user.status}. Please contact support.`);
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw ApiError.unauthorized('Invalid email or password');
    }

    // Update lastActiveAt
    user.lastActiveAt = new Date();
    await user.save();

    const accessToken = generateAccessToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    const refreshToken = generateRefreshToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    await RefreshToken.create({
      userId: user._id,
      token: refreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return ApiResponse.success(res, 'Login successful', {
      user: {
        id: user._id,
        email: user.email,
        role: user.role,
        emailVerified: user.emailVerified,
        mustChangePassword: user.mustChangePassword || false,
        profileCreatedFor: user.profileCreatedFor,
      },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    next(error);
  }
};

export const googleLogin = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { googleId, email } = req.body;

    let user = await User.findOne({
      $or: [{ googleId }, { email: email.toLowerCase() }],
    });

    if (!user) {
      user = await User.create({
        email: email.toLowerCase(),
        googleId,
        role: 'user', // Always force user role for Google Sign In
        status: 'active',
        emailVerified: true, // Google emails are pre-verified
        profileCreatedFor: 'self',
      });
    } else if (!user.googleId) {
      user.googleId = googleId;
      user.emailVerified = true;
      await user.save();
    }

    if (user.status !== 'active') {
      throw ApiError.forbidden(`Your account is ${user.status}`);
    }

    const accessToken = generateAccessToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    const refreshToken = generateRefreshToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    await RefreshToken.create({
      userId: user._id,
      token: refreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return ApiResponse.success(res, 'Google login successful', {
      user: {
        id: user._id,
        email: user.email,
        role: user.role,
        emailVerified: user.emailVerified,
        profileCreatedFor: user.profileCreatedFor,
      },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    next(error);
  }
};

export const verifyEmail = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const token = (req.query.token as string) || req.body.token;
    if (!token) {
      throw ApiError.badRequest('Verification token is required');
    }

    const emailToken = await EmailToken.findOne({ token, type: 'verify_email' });
    if (!emailToken) {
      throw ApiError.badRequest('Invalid or expired verification link');
    }

    const user = await User.findById(emailToken.userId);
    if (!user) {
      throw ApiError.notFound('User not found');
    }

    user.emailVerified = true;
    await user.save();

    await EmailToken.deleteOne({ _id: emailToken._id });

    // If request accepts HTML (direct click from email client browser)
    if (req.accepts('html')) {
      return res.send(`
        <div style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h1 style="color: #F2457B;">Email Verified Successfully!</h1>
          <p>Thank you for verifying your email. You can now return to the Rishta App and complete your profile.</p>
        </div>
      `);
    }

    return ApiResponse.success(res, 'Email verified successfully', {
      emailVerified: true,
    });
  } catch (error) {
    next(error);
  }
};

export const resendVerification = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      // Return success to prevent email enumeration
      return ApiResponse.success(res, 'If an account exists, a verification link has been sent');
    }

    if (user.emailVerified) {
      throw ApiError.badRequest('Email is already verified');
    }

    // Delete existing tokens for this user
    await EmailToken.deleteMany({ userId: user._id, type: 'verify_email' });

    const token = generateRandomToken();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await EmailToken.create({
      userId: user._id,
      token,
      type: 'verify_email',
      expiresAt,
    });

    await EmailService.sendVerificationEmail(user.email, token);

    return ApiResponse.success(res, 'Verification link sent to your email address');
  } catch (error) {
    next(error);
  }
};

export const forgotPassword = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      return ApiResponse.success(res, 'If an account exists, a password reset link has been sent');
    }

    await EmailToken.deleteMany({ userId: user._id, type: 'reset_password' });

    const token = generateRandomToken();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour expiration
    await EmailToken.create({
      userId: user._id,
      token,
      type: 'reset_password',
      expiresAt,
    });

    await EmailService.sendPasswordResetEmail(user.email, token);

    return ApiResponse.success(res, 'Password reset link sent to your email address');
  } catch (error) {
    next(error);
  }
};

export const resetPassword = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { token, newPassword } = req.body;

    const emailToken = await EmailToken.findOne({ token, type: 'reset_password' });
    if (!emailToken) {
      throw ApiError.badRequest('Invalid or expired password reset link');
    }

    const user = await User.findById(emailToken.userId);
    if (!user) {
      throw ApiError.notFound('User not found');
    }

    user.password = await bcrypt.hash(newPassword, 12);
    user.mustChangePassword = false;
    await user.save();

    // Invalidate all tokens for this user
    await EmailToken.deleteMany({ userId: user._id });
    await RefreshToken.deleteMany({ userId: user._id });

    return ApiResponse.success(res, 'Password reset successful. You can now log in with your new password.');
  } catch (error) {
    next(error);
  }
};

export const refreshTokens = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { refreshToken } = req.body;

    const existingTokenDoc = await RefreshToken.findOne({ token: refreshToken });
    if (!existingTokenDoc) {
      throw ApiError.unauthorized('Invalid or revoked refresh token');
    }

    const decoded = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET) as { userId: string };
    const user = await User.findById(decoded.userId);

    if (!user || user.status !== 'active') {
      throw ApiError.unauthorized('User not found or inactive');
    }

    // Delete old refresh token (rotate token)
    await RefreshToken.deleteOne({ _id: existingTokenDoc._id });

    const newAccessToken = generateAccessToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    const newRefreshToken = generateRefreshToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    await RefreshToken.create({
      userId: user._id,
      token: newRefreshToken,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return ApiResponse.success(res, 'Tokens refreshed successfully', {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await RefreshToken.deleteOne({ token: refreshToken });
    }
    if (req.user) {
      await RefreshToken.deleteMany({ userId: req.user._id });
    }
    return ApiResponse.success(res, 'Logged out successfully');
  } catch (error) {
    next(error);
  }
};

export const deleteAccount = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!._id;

    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound('User account not found');
    }

    if (user.role === 'admin') {
      throw ApiError.forbidden('Admin accounts cannot be deleted via the client API.');
    }

    user.status = 'deleted';
    await user.save();

    // Revoke all tokens
    await RefreshToken.deleteMany({ userId });
    await EmailToken.deleteMany({ userId });

    return ApiResponse.success(res, 'Your account has been deleted successfully.');
  } catch (error) {
    next(error);
  }
};

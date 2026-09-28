import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { ApiError } from '../utils/apiError';
import { User, IUser } from '../models/user.model';

export interface AuthenticatedRequest extends Request {
  user?: IUser;
}

export const authenticate = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(ApiError.unauthorized('Access token missing or malformed'));
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as { userId: string; role: string };

    const user = await User.findById(decoded.userId);
    if (!user) {
      return next(ApiError.unauthorized('User associated with token no longer exists'));
    }

    if (user.status !== 'active') {
      return next(ApiError.forbidden(`Account is ${user.status}. Access denied.`));
    }

    // Update lastActiveAt timestamp asynchronously
    User.findByIdAndUpdate(user._id, { lastActiveAt: new Date() }).exec();

    req.user = user;
    return next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError || error instanceof jwt.TokenExpiredError) {
      return next(ApiError.unauthorized('Invalid or expired authentication token'));
    }
    return next(error);
  }
};

export const requireAdmin = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  if (!req.user || req.user.role !== 'admin') {
    return next(ApiError.forbidden('Admin privilege required to access this resource'));
  }
  return next();
};

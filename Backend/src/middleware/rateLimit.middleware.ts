import rateLimit from 'express-rate-limit';
import { ApiResponse } from '../utils/apiResponse';

/**
 * General API Rate Limiter (100 requests per 15 minutes)
 */
export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return ApiResponse.error(
      res,
      'Too many requests from this IP, please try again after 15 minutes',
      null,
      429
    );
  },
});

/**
 * Auth Rate Limiter for Login/Register (5 requests per 15 minutes)
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    return ApiResponse.error(
      res,
      'Too many authentication attempts, please try again after 15 minutes',
      null,
      429
    );
  },
});

import { Request, Response } from 'express';
import mongoose from 'mongoose';
import { ApiResponse } from '../utils/apiResponse';
import { env } from '../config/env';

export const getHealthStatus = async (req: Request, res: Response): Promise<Response> => {
  const dbStateMap: Record<number, string> = {
    0: 'disconnected',
    1: 'connected',
    2: 'connecting',
    3: 'disconnecting',
  };

  const healthData = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: env.NODE_ENV,
    uptimeSeconds: Math.floor(process.uptime()),
    database: {
      status: dbStateMap[mongoose.connection.readyState] || 'unknown',
      host: mongoose.connection.host || 'N/A',
      name: mongoose.connection.name || 'N/A',
    },
    version: '1.0.0',
  };

  return ApiResponse.success(res, 'Rishta API is up and running smoothly', healthData, 200);
};

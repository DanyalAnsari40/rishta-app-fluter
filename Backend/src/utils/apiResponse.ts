import { Response } from 'express';

export interface ApiResponsePayload<T = any> {
  success: boolean;
  message: string;
  data?: T | null;
  errors?: any;
}

export class ApiResponse {
  static success<T>(
    res: Response,
    message: string = 'Operation successful',
    data?: T,
    statusCode: number = 200
  ): Response {
    const payload: ApiResponsePayload<T> = {
      success: true,
      message,
      data: data !== undefined ? data : null,
    };
    return res.status(statusCode).json(payload);
  }

  static error(
    res: Response,
    message: string = 'An error occurred',
    errors: any = null,
    statusCode: number = 500
  ): Response {
    const payload: ApiResponsePayload = {
      success: false,
      message,
      errors: errors !== undefined ? errors : null,
    };
    return res.status(statusCode).json(payload);
  }
}

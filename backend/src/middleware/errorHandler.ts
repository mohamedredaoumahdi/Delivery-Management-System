import { Request, Response, NextFunction } from 'express';
import { Prisma } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { logger } from '@/utils/logger';
import { config } from '@/config/config';

const handlePrismaError = (error: Prisma.PrismaClientKnownRequestError): AppError => {
  switch (error.code) {
    case 'P2002':
      return new AppError('Duplicate field value. Please use another value.', 400);
    case 'P2014':
      return new AppError('Invalid ID. Please provide a valid ID.', 400);
    case 'P2003':
      return new AppError('Invalid input data. Related record not found.', 400);
    case 'P2025':
      return new AppError('Record not found.', 404);
    default:
      return new AppError('Database error occurred.', 500);
  }
};

const handleJWTError = (): AppError => 
  new AppError('Invalid token. Please log in again.', 401);

const handleJWTExpiredError = (): AppError =>
  new AppError('Your token has expired. Please log in again.', 401);

const sendErrorDev = (err: AppError, req: Request, res: Response): void => {
  // API error
  if (req.originalUrl.startsWith('/api')) {
    res.status(err.statusCode).json({
      status: err.status,
      error: err,
      message: err.message,
      stack: err.stack,
    });
  }
};

const sendErrorProd = (err: AppError, req: Request, res: Response): void => {
  // API error
  if (req.originalUrl.startsWith('/api')) {
    // Operational, trusted error: send message to client
    if (err.isOperational) {
      res.status(err.statusCode).json({
        status: err.status,
        message: err.message,
      });
    } else {
      // Programming or other unknown error: don't leak error details
      logger.error('Unexpected error:', err);

      res.status(500).json({
        status: 'error',
        message: 'Something went wrong!',
      });
    }
  }
};

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // Handle AppError instances directly
  if (err instanceof AppError) {
    if (config.nodeEnv === 'development') {
      sendErrorDev(err, req, res);
    } else {
      sendErrorProd(err, req, res);
    }
    return;
  }

  // Handle other error types
  if (config.nodeEnv === 'development') {
    sendErrorDev(err, req, res);
  } else {
    let error = { ...err };
    error.message = err.message;

    // Handle specific error types
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      error = handlePrismaError(error);
    }
    if (error.name === 'JsonWebTokenError') error = handleJWTError();
    if (error.name === 'TokenExpiredError') error = handleJWTExpiredError();

    sendErrorProd(error, req, res);
  }
}; 
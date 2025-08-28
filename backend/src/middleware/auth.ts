import { Response, NextFunction } from 'express';
import * as jwt from 'jsonwebtoken';
import { config } from '@/config/config';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '@/types/express';

interface JwtPayload {
  userId: string;
  role: string;
  iat: number;
  exp: number;
}

export const auth = async (req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      throw new AppError('Access denied. No token provided.', 401);
    }

    const decoded = jwt.verify(token, config.jwtSecret) as JwtPayload;

    // Get user from database
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        isActive: true,
        isEmailVerified: true,
      },
    });

    if (!user) {
      throw new AppError('Token is not valid.', 401);
    }

    if (!user.isActive) {
      throw new AppError('Account has been deactivated.', 401);
    }

    // Optional: enforce email verification for protected routes
    // if (!user.isEmailVerified) {
    //   throw new AppError('Email not verified.', 403);
    // }

    req.user = user;
    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      next(new AppError('Token is not valid.', 401));
    } else {
      next(error);
    }
  }
}; 
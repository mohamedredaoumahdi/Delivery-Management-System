import { Response, NextFunction } from 'express';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '@/types/express';

export const requireRole = (roles: string[]) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      throw new AppError('Authentication required.', 401);
    }

    if (!roles.includes(req.user.role)) {
      throw new AppError('Insufficient permissions.', 403);
    }

    next();
  };
}; 
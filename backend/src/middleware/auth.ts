// src/middleware/auth.ts
import type { Request, Response, NextFunction } from 'express';
import * as jwt from 'jsonwebtoken';
import { config } from '@/config/config';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';

interface JwtPayload {
  userId: string;
  role: string;
  iat: number;
  exp: number;
}

interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    email: string;
    name: string;
    role: string;
  };
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
      },
    });

    if (!user) {
      throw new AppError('Token is not valid.', 401);
    }

    if (!user.isActive) {
      throw new AppError('Account has been deactivated.', 401);
    }

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

// src/middleware/requireRole.ts
import { Response, NextFunction } from 'express';
import { AppError } from '@/utils/appError';

interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    email: string;
    name: string;
    role: string;
  };
}

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

// src/controllers/authController.ts
import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '@/config/database';
import { config } from '@/config/config';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { SessionService } from '@/config/redis';
import { EmailService } from '@/services/emailService';

interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    email: string;
    name: string;
    role: string;
  };
}

export class AuthController {
  private generateTokens(userId: string, role: string) {
    const accessToken = jwt.sign(
      { userId, role },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn }
    );

    const refreshToken = jwt.sign(
      { userId, role, tokenId: uuidv4() },
      config.jwtRefreshSecret,
      { expiresIn: config.jwtRefreshExpiresIn }
    );

    return { accessToken, refreshToken };
  }

  register = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { email, password, name, role = 'CUSTOMER' } = req.body;

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return next(new AppError('User with this email already exists', 400));
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Create user
    const user = await prisma.user.create({
      data: {
        email,
        name,
        passwordHash,
        role,
      },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
      },
    });

    // Generate tokens
    const { accessToken, refreshToken } = this.generateTokens(user.id, user.role);

    // Store refresh token in database
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      },
    });

    // Send welcome email (optional)
    try {
      await EmailService.sendWelcomeEmail(user.email, user.name);
    } catch (error) {
      console.error('Failed to send welcome email:', error);
    }

    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      data: {
        user,
        accessToken,
        refreshToken,
      },
    });
  });

  login = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { email, password } = req.body;

    // Find user and include password for comparison
    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        passwordHash: true,
        isActive: true,
      },
    });

    if (!user || !user.isActive) {
      return next(new AppError('Invalid email or password', 401));
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      return next(new AppError('Invalid email or password', 401));
    }

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    // Generate tokens
    const { accessToken, refreshToken } = this.generateTokens(user.id, user.role);

    // Store refresh token in database
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      },
    });

    // Remove password from response
    const { passwordHash, ...userResponse } = user;

    res.json({
      status: 'success',
      message: 'Login successful',
      data: {
        user: userResponse,
        accessToken,
        refreshToken,
      },
    });
  });

  refreshToken = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return next(new AppError('Refresh token is required', 400));
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, config.jwtRefreshSecret) as any;
    } catch (error) {
      return next(new AppError('Invalid refresh token', 401));
    }

    // Check if refresh token exists in database
    const storedToken = await prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    });

    if (!storedToken || storedToken.expiresAt < new Date()) {
      return next(new AppError('Refresh token is invalid or expired', 401));
    }

    // Generate new tokens
    const { accessToken, refreshToken: newRefreshToken } = this.generateTokens(
      storedToken.user.id,
      storedToken.user.role
    );

    // Delete old refresh token and create new one
    await prisma.refreshToken.delete({
      where: { token: refreshToken },
    });

    await prisma.refreshToken.create({
      data: {
        token: newRefreshToken,
        userId: storedToken.user.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      },
    });

    res.json({
      status: 'success',
      data: {
        accessToken,
        refreshToken: newRefreshToken,
      },
    });
  });

  logout = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const { refreshToken } = req.body;

    if (refreshToken) {
      // Delete refresh token from database
      await prisma.refreshToken.deleteMany({
        where: { token: refreshToken },
      });
    }

    // Clear user session from Redis if using sessions
    if (req.user) {
      await SessionService.deleteSession(req.user.id);
    }

    res.json({
      status: 'success',
      message: 'Logged out successfully',
    });
  });

  forgotPassword = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { email } = req.body;

    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      // Don't reveal whether user exists or not
      return res.json({
        status: 'success',
        message: 'If an account with that email exists, we sent you a password reset link.',
      });
    }

    // Generate reset token
    const resetToken = uuidv4();
    const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    // Store reset token in Redis
    await SessionService.setSession(
      `password-reset:${resetToken}`,
      { userId: user.id, email: user.email },
      3600 // 1 hour
    );

    // Send reset email
    try {
      await EmailService.sendPasswordResetEmail(user.email, user.name, resetToken);
    } catch (error) {
      console.error('Failed to send password reset email:', error);
      return next(new AppError('Failed to send password reset email', 500));
    }

    res.json({
      status: 'success',
      message: 'If an account with that email exists, we sent you a password reset link.',
    });
  });

  resetPassword = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { token, newPassword } = req.body;

    // Get reset token data from Redis
    const resetData = await SessionService.getSession(`password-reset:${token}`);

    if (!resetData) {
      return next(new AppError('Invalid or expired reset token', 400));
    }

    // Hash new password
    const passwordHash = await bcrypt.hash(newPassword, 12);

    // Update user password
    await prisma.user.update({
      where: { id: resetData.userId },
      data: { passwordHash },
    });

    // Delete reset token
    await SessionService.deleteSession(`password-reset:${token}`);

    // Delete all refresh tokens for this user (force re-login)
    await prisma.refreshToken.deleteMany({
      where: { userId: resetData.userId },
    });

    res.json({
      status: 'success',
      message: 'Password reset successfully',
    });
  });

  verifyEmail = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { token } = req.body;

    // This would typically verify an email verification token
    // Implementation depends on your email verification flow
    
    res.json({
      status: 'success',
      message: 'Email verified successfully',
    });
  });
}
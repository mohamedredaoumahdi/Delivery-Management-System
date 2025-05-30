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
import { AuthenticatedRequest } from '@/types/express';

export class AuthController {
  private generateTokens(userId: string, role: string) {
    const accessToken = jwt.sign(
      { userId, role },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn as jwt.SignOptions['expiresIn'] }
    );

    const refreshToken = jwt.sign(
      { userId, role, tokenId: uuidv4() },
      config.jwtRefreshSecret,
      { expiresIn: config.jwtRefreshExpiresIn as jwt.SignOptions['expiresIn'] }
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

    // Check if user exists
    if (!user) {
      return next(new AppError('No account found with this email address. Please check your email or sign up for a new account.', 404));
    }

    // Check if password is correct
    if (!(await bcrypt.compare(password, user.passwordHash))) {
      return next(new AppError('Incorrect password. Please check your password and try again.', 401));
    }

    // Check if account is active
    if (!user.isActive) {
      return next(new AppError('Your account has been deactivated. Please contact support for assistance.', 403));
    }

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

    // Update last login
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    res.json({
      status: 'success',
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
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

    try {
      const decoded = jwt.verify(refreshToken, config.jwtRefreshSecret) as {
        userId: string;
        role: string;
        tokenId: string;
      };

      // Check if refresh token exists in database
      const storedToken = await prisma.refreshToken.findFirst({
        where: {
          token: refreshToken,
          userId: decoded.userId,
          expiresAt: { gt: new Date() },
        },
      });

      if (!storedToken) {
        return next(new AppError('Invalid refresh token', 401));
      }

      // Generate new tokens
      const { accessToken: newAccessToken, refreshToken: newRefreshToken } = this.generateTokens(
        decoded.userId,
        decoded.role
      );

      // Delete old refresh token
      await prisma.refreshToken.delete({
        where: { id: storedToken.id },
      });

      // Store new refresh token
      await prisma.refreshToken.create({
        data: {
          token: newRefreshToken,
          userId: decoded.userId,
          expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        },
      });

      res.json({
        status: 'success',
        message: 'Token refreshed successfully',
        data: {
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        },
      });
    } catch (error) {
      return next(new AppError('Invalid refresh token', 401));
    }
  });

  logout = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const { refreshToken } = req.body;

    if (refreshToken) {
      // Delete refresh token from database
      await prisma.refreshToken.deleteMany({
        where: {
          token: refreshToken,
          userId: req.user!.id,
        },
      });
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
      return next(new AppError('No user found with this email address', 404));
    }

    // Generate reset token
    const resetToken = jwt.sign(
      { userId: user.id },
      config.jwtSecret,
      { expiresIn: '1h' }
    );

    // Store reset token in database
    await prisma.passwordResetToken.create({
      data: {
        tokenHash: await bcrypt.hash(resetToken, 12),
        userId: user.id,
        expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
      },
    });

    // Send reset email
    try {
      await EmailService.sendPasswordResetEmail(user.email, resetToken);
    } catch (error) {
      console.error('Failed to send password reset email:', error);
      return next(new AppError('Failed to send password reset email', 500));
    }

    res.json({
      status: 'success',
      message: 'Password reset instructions sent to your email',
    });
  });

  resetPassword = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { token, password } = req.body;

    try {
      const decoded = jwt.verify(token, config.jwtSecret) as { userId: string };

      // Check if reset token exists and is valid
      const resetToken = await prisma.passwordResetToken.findFirst({
        where: {
          tokenHash: await bcrypt.hash(token, 12),
          userId: decoded.userId,
          expiresAt: { gt: new Date() },
        },
      });

      if (!resetToken) {
        return next(new AppError('Invalid or expired reset token', 400));
      }

      // Update password
      const passwordHash = await bcrypt.hash(password, 12);
      await prisma.user.update({
        where: { id: decoded.userId },
        data: { passwordHash },
      });

      // Delete reset token
      await prisma.passwordResetToken.delete({
        where: { id: resetToken.id },
      });

      res.json({
        status: 'success',
        message: 'Password reset successful',
      });
    } catch (error) {
      return next(new AppError('Invalid reset token', 400));
    }
  });

  verifyEmail = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { token } = req.params;

    try {
      const decoded = jwt.verify(token, config.jwtSecret) as { userId: string };

      // Check if verification token exists and is valid
      const verificationToken = await prisma.emailVerificationToken.findFirst({
        where: {
          token,
          userId: decoded.userId,
          expiresAt: { gt: new Date() },
        },
      });

      if (!verificationToken) {
        return next(new AppError('Invalid or expired verification token', 400));
      }

      // Update user's email verification status
      await prisma.user.update({
        where: { id: decoded.userId },
        data: { isEmailVerified: true },
      });

      // Delete verification token
      await prisma.emailVerificationToken.delete({
        where: { id: verificationToken.id },
      });

      res.json({
        status: 'success',
        message: 'Email verified successfully',
      });
    } catch (error) {
      return next(new AppError('Invalid verification token', 400));
    }
  });
} 
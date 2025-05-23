import type { Request, Response, NextFunction } from 'express';
import { PrismaClient, UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';
import * as jwt from 'jsonwebtoken';
import { validationResult } from 'express-validator';
import { v4 as uuidv4 } from 'uuid';
import sendEmail from '@/utils/sendEmail'; // Import sendEmail utility
import { config } from '@/config/config';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { SessionService } from '@/config/redis';

const prisma = new PrismaClient();

// Helper function to generate JWT
const generateToken = (id: string): string => {
  return jwt.sign({ id }, process.env.JWT_SECRET!, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });
};

// Helper function to generate Refresh Token
const generateRefreshToken = (userId: string): string => {
  const token = jwt.sign({ userId }, process.env.JWT_REFRESH_SECRET!, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN,
  });
  return token;
};

// Create a simple email service interface
interface EmailService {
  sendWelcomeEmail(email: string, name: string): Promise<void>;
  sendPasswordResetEmail(email: string, name: string, token: string): Promise<void>;
}

// Create a mock email service implementation
class MockEmailService implements EmailService {
  async sendWelcomeEmail(email: string, name: string): Promise<void> {
    console.log(`Welcome email sent to ${email} for ${name}`);
  }

  async sendPasswordResetEmail(email: string, name: string, token: string): Promise<void> {
    console.log(`Password reset email sent to ${email} for ${name} with token ${token}`);
  }
}

const EmailService = new MockEmailService();

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
    const accessTokenOptions: jwt.SignOptions = {
      expiresIn: config.jwtExpiresIn
    };

    const refreshTokenOptions: jwt.SignOptions = {
      expiresIn: config.jwtRefreshExpiresIn
    };

    const accessToken = jwt.sign(
      { userId, role },
      config.jwtSecret,
      accessTokenOptions
    );

    const refreshToken = jwt.sign(
      { userId, role, tokenId: uuidv4() },
      config.jwtRefreshSecret,
      refreshTokenOptions
    );

    return { accessToken, refreshToken };
  }

  /**
   * @desc    Register a new user
   * @route   POST /api/v1/auth/register
   * @access  Public
   */
  register = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    // Check for validation errors from middleware (Joi/Zod)
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email, password, role } = req.body;

    try {
      // Check if user already exists
      const userExists = await prisma.user.findUnique({
        where: {
          email,
        },
      });

      if (userExists) {
        return res.status(400).json({ message: 'User already exists' });
      }

      // Hash password
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);

      // Create user
      const user = await prisma.user.create({
        data: {
          name,
          email,
          passwordHash: hashedPassword,
          role: role || UserRole.CUSTOMER, // Default role to CUSTOMER if not provided
        },
      });

      if (user) {
        // Generate email verification token
        const verificationToken = uuidv4();
        const verificationExpiresAt = new Date(Date.now() + 3600000 * 24); // 24 hours

        // Save verification token in the database
        await prisma.emailVerificationToken.create({
          data: {
            token: verificationToken,
            userId: user.id,
            expiresAt: verificationExpiresAt,
          },
        });

        // Send email verification email
        const verificationUrl = `${process.env.FRONTEND_URL}/verify-email?token=${verificationToken}`;

        try {
          await sendEmail({
            email: user.email,
            subject: 'Verify Your Email Address',
            message: `Thank you for registering! Please click the following link to verify your email address: ${verificationUrl}\n\nIf you did not create an account, please ignore this email.`, // Added instructional text
          });
          console.log(`Email verification email sent to ${user.email}`);
        } catch (emailError) {
          console.error('Error sending email verification email:', emailError);
          // Continue with registration even if email sending fails
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

        // Send welcome email (optional)
        try {
          await EmailService.sendWelcomeEmail(user.email, user.name);
        } catch (error) {
          console.error('Failed to send welcome email:', error);
        }

        res.status(201).json({
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          accessToken,
          refreshToken,
        });
      } else {
        res.status(400).json({ message: 'Invalid user data' });
      }

    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server Error' });
    }
  });

  /**
   * @desc    Login user
   * @route   POST /api/v1/auth/login
   * @access  Public
   */
  login = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    // Check for validation errors (assuming validation middleware is used)
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;

    try {
      // Find user by email
      const user = await prisma.user.findUnique({
        where: {
          email,
        },
      });

      // Check if user exists and password is correct
      if (user && (await bcrypt.compare(password, user.passwordHash))) {
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

        res.json({
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          accessToken,
          refreshToken,
        });
      } else {
        res.status(401).json({ message: 'Invalid credentials' });
      }

    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server Error' });
    }
  });

  /**
   * @desc    Refresh JWT token
   * @route   POST /api/v1/auth/refresh
   * @access  Public
   */
  refreshToken = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { refreshToken } = req.body; // Assuming refresh token is sent in the body

    if (!refreshToken) {
      return res.status(401).json({ message: 'Refresh token not provided' });
    }

    try {
      // Find the refresh token in the database
      const storedRefreshToken = await prisma.refreshToken.findUnique({
        where: {
          token: refreshToken,
        },
        include: {
          user: true, // Include the associated user
        },
      });

      if (!storedRefreshToken) {
        return res.status(403).json({ message: 'Invalid refresh token' });
      }

      // Check if the refresh token has expired
      if (storedRefreshToken.expiresAt < new Date()) {
        // Optionally, remove expired token
        await prisma.refreshToken.delete({
          where: {
            id: storedRefreshToken.id,
          },
        });
        return res.status(403).json({ message: 'Refresh token expired' });
      }

      // Check if the associated user is active
      const user = storedRefreshToken.user;
      if (!user || !user.isActive) {
        return res.status(403).json({ message: 'User not found or inactive' });
      }

      // Generate a new access token
      const newAccessToken = generateToken(user.id);

      // Optional: Implement refresh token rotation
      // Invalidate the old refresh token and generate a new one
      // await prisma.refreshToken.delete({
      //   where: {
      //     id: storedRefreshToken.id,
      //   },
      // });
      // const newRefreshToken = generateRefreshToken(user.id);
      // await prisma.refreshToken.create({
      //   data: {
      //     token: newRefreshToken,
      //     userId: user.id,
      //     expiresAt: new Date(Date.now() + (parseInt(process.env.JWT_REFRESH_EXPIRES_IN!) * 24 * 60 * 60 * 1000)), // Example: 7 days
      //   },
      // });

      res.json({
        accessToken: newAccessToken,
        // refreshToken: newRefreshToken, // Include if rotating refresh tokens
      });

    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server Error' });
    }
  });

  /**
   * @desc    Logout user
   * @route   POST /api/v1/auth/logout
   * @access  Private
   */
  logout = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    // Assuming auth middleware populates req.user with the authenticated user
    const userId = (req as any).user?.id; // Access user ID from the request object

    if (!userId) {
      return res.status(401).json({ message: 'Not authenticated' });
    }

    try {
      // Delete all refresh tokens for the user
      await prisma.refreshToken.deleteMany({
        where: {
          userId: userId,
        },
      });

      // Clear user session from Redis if using sessions
      if (req.user) {
        await SessionService.deleteSession(req.user.id);
      }

      res.status(200).json({ message: 'Logged out successfully' });

    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server Error' });
    }
  });

  /**
   * @desc    Forgot password
   * @route   POST /api/v1/auth/forgot-password
   * @access  Public
   */
  forgotPassword = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { email } = req.body;

    try {
      const user = await prisma.user.findUnique({
        where: {
          email,
        },
      });

      // Even if the user doesn't exist, send a generic success message to prevent email enumeration
      if (!user) {
        console.log(`Forgot password attempt for non-existent email: ${email}`);
        return res.status(200).json({ message: 'If a user with that email exists, a password reset link has been sent.' });
      }

      // Generate a unique password reset token (UUID)
      const resetToken = uuidv4();

      // Calculate expiry time (e.g., 1 hour from now)
      const expiresAt = new Date(Date.now() + 3600000); // 1 hour in milliseconds

      // Hash the token before saving to the database (for security)
      const tokenHash = await bcrypt.hash(resetToken, 10);

      // Save the hashed token and expiry time in the database, linked to the user.
      // First, delete any existing reset tokens for this user to ensure only one is valid at a time.
      await prisma.passwordResetToken.deleteMany({
        where: {
          userId: user.id,
        },
      });

      await prisma.passwordResetToken.create({
        data: {
          tokenHash: tokenHash,
          userId: user.id,
          expiresAt: expiresAt,
        },
      });

      // Send email to user with a link containing the reset token.
      const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;

      try {
        await sendEmail({
          email: user.email,
          subject: 'Password Reset Request',
          message: `You requested a password reset. Please use the following link to reset your password: ${resetUrl}\n\nIf you did not request this, please ignore this email.`, // Added instructional text
        });
        console.log(`Password reset email sent to ${user.email}`);
      } catch (emailError) {
        console.error('Error sending password reset email:', emailError);
        // Although email sending failed, we still send a success response to the user
        // to avoid exposing whether the email exists.
      }

      res.status(200).json({ message: 'If a user with that email exists, a password reset link has been sent.' });

    } catch (error) {
      console.error(error);
      // @todo: Implement proper error handling and logging
      res.status(500).json({ message: 'Server Error' });
    }
  });

  /**
   * @desc    Reset password
   * @route   POST /api/v1/auth/reset-password/:token
   * @access  Public
   */
  resetPassword = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { token } = req.params; // Assuming token is in URL parameters
    const { password } = req.body;

    try {
      // Find the password reset token in the database using the token hash
      // You will need to hash the received token and compare it with the tokenHash stored in the database.
      // Include the associated user.
      // Check if the token exists and is not expired.

      // Since the token stored is a hash, we need to iterate through potential tokens
      // and compare the provided token with the stored hash.
      const resetTokens = await prisma.passwordResetToken.findMany({
        include: { user: true },
      });

      let foundToken = null;
      for (const storedToken of resetTokens) {
        const isMatch = await bcrypt.compare(token, storedToken.tokenHash);
        if (isMatch && storedToken.expiresAt > new Date()) {
          foundToken = storedToken;
          break;
        }
      }

      if (!foundToken) {
        return res.status(400).json({ message: 'Invalid or expired reset token' });
      }

      const user = foundToken.user;

      // Hash the new password
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);

      // Update user's password
      await prisma.user.update({
        where: {
          id: user.id,
        },
        data: {
          passwordHash: hashedPassword,
        },
      });

      // Delete the used reset token from the database
      await prisma.passwordResetToken.delete({
        where: {
          id: foundToken.id,
        },
      });

      res.status(200).json({ message: 'Password reset successfully' });

    } catch (error) {
      console.error(error);
      // @todo: Implement proper error handling and logging
      res.status(500).json({ message: 'Server Error' });
    }
  });

  /**
   * @desc    Verify email
   * @route   POST /api/v1/auth/verify-email/:token
   * @access  Public
   */
  verifyEmail = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { token } = req.params; // Assuming token is in URL parameters

    try {
      // Find the email verification token in the database using the token.
      // Include the associated user.
      // Check if the token exists and is not expired.
      const emailVerificationToken = await prisma.emailVerificationToken.findFirst({
        where: {
          token: token,
          expiresAt: { gt: new Date() }, // Check if token is not expired
        },
        include: { user: true },
      });

      if (!emailVerificationToken) {
        return res.status(400).json({ message: 'Invalid or expired verification token' });
      }

      const user = emailVerificationToken.user;

      // Update user's email verification status
      await prisma.user.update({
        where: {
          id: user.id,
        },
        data: {
          isEmailVerified: true,
        },
      });

      // Delete the used verification token from the database
      await prisma.emailVerificationToken.delete({
        where: {
          id: emailVerificationToken.id,
        },
      });

      res.status(200).json({ message: 'Email verified successfully' });

    } catch (error) {
      console.error(error);
      // @todo: Implement proper error handling and logging
      res.status(500).json({ message: 'Server Error' });
    }
  });
} 
import { config } from '@/config/config';
import sendEmail from '@/utils/sendEmail';

export class EmailService {
  static async sendWelcomeEmail(email: string, name: string): Promise<void> {
    const subject = 'Welcome to Our Platform';
    const message = `Hello ${name},\n\nWelcome to our platform! We're excited to have you on board.\n\nBest regards,\nThe Team`;

    await sendEmail({
      email,
      subject,
      message,
    });
  }

  static async sendPasswordResetEmail(email: string, token: string): Promise<void> {
    const resetUrl = `${config.frontendUrl}/reset-password?token=${token}`;
    const subject = 'Password Reset Request';
    const message = `You requested a password reset. Please use the following link to reset your password: ${resetUrl}\n\nIf you did not request this, please ignore this email.`;

    await sendEmail({
      email,
      subject,
      message,
    });
  }

  static async sendVerificationEmail(email: string, token: string): Promise<void> {
    const verifyUrl = `${config.frontendUrl}/verify-email?token=${token}`;
    const subject = 'Verify your email address';
    const message = `Please verify your email by visiting: ${verifyUrl}\n\nIf you did not create an account, please ignore this email.`;

    await sendEmail({
      email,
      subject,
      message,
    });
  }
} 
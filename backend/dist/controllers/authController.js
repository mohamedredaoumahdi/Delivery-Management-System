"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const client_1 = require("@prisma/client");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jwt = __importStar(require("jsonwebtoken"));
const express_validator_1 = require("express-validator");
const uuid_1 = require("uuid");
const sendEmail_1 = __importDefault(require("@/utils/sendEmail"));
const config_1 = require("@/config/config");
const appError_1 = require("@/utils/appError");
const catchAsync_1 = require("@/utils/catchAsync");
const redis_1 = require("@/config/redis");
const prisma = new client_1.PrismaClient();
class MockEmailService {
    async sendWelcomeEmail(email, name) {
        console.log(`Welcome email sent to ${email} for ${name}`);
    }
    async sendPasswordResetEmail(email, name, token) {
        console.log(`Password reset email sent to ${email} for ${name} with token ${token}`);
    }
}
const emailService = new MockEmailService();
class AuthController {
    generateTokens(userId, role) {
        const accessTokenOptions = {
            expiresIn: config_1.config.jwtExpiresIn
        };
        const refreshTokenOptions = {
            expiresIn: config_1.config.jwtRefreshExpiresIn
        };
        const accessToken = jwt.sign({ userId, role }, config_1.config.jwtSecret, accessTokenOptions);
        const refreshToken = jwt.sign({ userId, role, tokenId: (0, uuid_1.v4)() }, config_1.config.jwtRefreshSecret, refreshTokenOptions);
        return { accessToken, refreshToken };
    }
    register = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const errors = (0, express_validator_1.validationResult)(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        const { name, email, password, role } = req.body;
        try {
            const userExists = await prisma.user.findUnique({
                where: {
                    email,
                },
            });
            if (userExists) {
                throw new appError_1.AppError('User already exists', 400);
            }
            const salt = await bcryptjs_1.default.genSalt(10);
            const hashedPassword = await bcryptjs_1.default.hash(password, salt);
            const user = await prisma.user.create({
                data: {
                    name,
                    email,
                    passwordHash: hashedPassword,
                    role: role || client_1.UserRole.CUSTOMER,
                },
            });
            if (!user) {
                return res.status(400).json({ message: 'Invalid user data' });
            }
            const verificationToken = (0, uuid_1.v4)();
            const verificationExpiresAt = new Date(Date.now() + 3600000 * 24);
            await prisma.emailVerificationToken.create({
                data: {
                    token: verificationToken,
                    userId: user.id,
                    expiresAt: verificationExpiresAt,
                },
            });
            const verificationUrl = `${config_1.config.frontendUrl}/verify-email?token=${verificationToken}`;
            try {
                await (0, sendEmail_1.default)({
                    email: user.email,
                    subject: 'Verify Your Email Address',
                    message: `Thank you for registering! Please click the following link to verify your email address: ${verificationUrl}\n\nIf you did not create an account, please ignore this email.`,
                });
                console.log(`Email verification email sent to ${user.email}`);
            }
            catch (emailError) {
                console.error('Error sending email verification email:', emailError);
            }
            const { accessToken, refreshToken } = this.generateTokens(user.id, user.role);
            await prisma.refreshToken.create({
                data: {
                    token: refreshToken,
                    userId: user.id,
                    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
                },
            });
            try {
                await emailService.sendWelcomeEmail(user.email, user.name);
            }
            catch (error) {
                console.error('Failed to send welcome email:', error);
            }
            return res.status(201).json({
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                accessToken,
                refreshToken,
            });
        }
        catch (error) {
            if (error instanceof appError_1.AppError) {
                throw error;
            }
            throw new appError_1.AppError('Server Error', 500);
        }
    });
    login = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const errors = (0, express_validator_1.validationResult)(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        const { email, password } = req.body;
        try {
            const user = await prisma.user.findUnique({
                where: {
                    email,
                },
            });
            if (!user || !(await bcryptjs_1.default.compare(password, user.passwordHash))) {
                throw new appError_1.AppError('Invalid credentials', 401);
            }
            await prisma.user.update({
                where: { id: user.id },
                data: { lastLoginAt: new Date() },
            });
            const { accessToken, refreshToken } = this.generateTokens(user.id, user.role);
            await prisma.refreshToken.create({
                data: {
                    token: refreshToken,
                    userId: user.id,
                    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
                },
            });
            return res.json({
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                accessToken,
                refreshToken,
            });
        }
        catch (error) {
            if (error instanceof appError_1.AppError) {
                throw error;
            }
            throw new appError_1.AppError('Server Error', 500);
        }
    });
    refreshToken = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            return res.status(401).json({ message: 'Refresh token not provided' });
        }
        try {
            const storedRefreshToken = await prisma.refreshToken.findUnique({
                where: {
                    token: refreshToken,
                },
                include: {
                    user: true,
                },
            });
            if (!storedRefreshToken) {
                return res.status(403).json({ message: 'Invalid refresh token' });
            }
            if (storedRefreshToken.expiresAt < new Date()) {
                await prisma.refreshToken.delete({
                    where: {
                        id: storedRefreshToken.id,
                    },
                });
                return res.status(403).json({ message: 'Refresh token expired' });
            }
            const user = storedRefreshToken.user;
            if (!user || !user.isActive) {
                return res.status(403).json({ message: 'User not found or inactive' });
            }
            const newAccessToken = this.generateTokens(user.id, user.role).accessToken;
            return res.json({
                accessToken: newAccessToken,
            });
        }
        catch (error) {
            console.error(error);
            return res.status(500).json({ message: 'Server Error' });
        }
    });
    logout = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({ message: 'Not authenticated' });
        }
        try {
            await prisma.refreshToken.deleteMany({
                where: {
                    userId: userId,
                },
            });
            if (req.user) {
                await redis_1.SessionService.deleteSession(req.user.id);
            }
            return res.status(200).json({ message: 'Logged out successfully' });
        }
        catch (error) {
            console.error(error);
            return res.status(500).json({ message: 'Server Error' });
        }
    });
    forgotPassword = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { email } = req.body;
        try {
            const user = await prisma.user.findUnique({
                where: {
                    email,
                },
            });
            if (!user) {
                console.log(`Forgot password attempt for non-existent email: ${email}`);
                return res.status(200).json({ message: 'If a user with that email exists, a password reset link has been sent.' });
            }
            const resetToken = (0, uuid_1.v4)();
            const expiresAt = new Date(Date.now() + 3600000);
            const tokenHash = await bcryptjs_1.default.hash(resetToken, 10);
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
            const resetUrl = `${config_1.config.frontendUrl}/reset-password?token=${resetToken}`;
            try {
                await (0, sendEmail_1.default)({
                    email: user.email,
                    subject: 'Password Reset Request',
                    message: `You requested a password reset. Please use the following link to reset your password: ${resetUrl}\n\nIf you did not request this, please ignore this email.`,
                });
                console.log(`Password reset email sent to ${user.email}`);
            }
            catch (emailError) {
                console.error('Error sending password reset email:', emailError);
            }
            return res.status(200).json({ message: 'If a user with that email exists, a password reset link has been sent.' });
        }
        catch (error) {
            console.error(error);
            return res.status(500).json({ message: 'Server Error' });
        }
    });
    resetPassword = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { token } = req.params;
        const { password } = req.body;
        try {
            const resetTokens = await prisma.passwordResetToken.findMany({
                include: { user: true },
            });
            let foundToken = null;
            for (const storedToken of resetTokens) {
                const isMatch = await bcryptjs_1.default.compare(token, storedToken.tokenHash);
                if (isMatch && storedToken.expiresAt > new Date()) {
                    foundToken = storedToken;
                    break;
                }
            }
            if (!foundToken) {
                return res.status(400).json({ message: 'Invalid or expired reset token' });
            }
            const user = foundToken.user;
            const salt = await bcryptjs_1.default.genSalt(10);
            const hashedPassword = await bcryptjs_1.default.hash(password, salt);
            await prisma.user.update({
                where: {
                    id: user.id,
                },
                data: {
                    passwordHash: hashedPassword,
                },
            });
            await prisma.passwordResetToken.delete({
                where: {
                    id: foundToken.id,
                },
            });
            return res.status(200).json({ message: 'Password reset successfully' });
        }
        catch (error) {
            console.error(error);
            return res.status(500).json({ message: 'Server Error' });
        }
    });
    verifyEmail = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { token } = req.params;
        try {
            const emailVerificationToken = await prisma.emailVerificationToken.findFirst({
                where: {
                    token: token,
                    expiresAt: { gt: new Date() },
                },
                include: { user: true },
            });
            if (!emailVerificationToken) {
                return res.status(400).json({ message: 'Invalid or expired verification token' });
            }
            const user = emailVerificationToken.user;
            await prisma.user.update({
                where: {
                    id: user.id,
                },
                data: {
                    isEmailVerified: true,
                },
            });
            await prisma.emailVerificationToken.delete({
                where: {
                    id: emailVerificationToken.id,
                },
            });
            return res.status(200).json({ message: 'Email verified successfully' });
        }
        catch (error) {
            console.error(error);
            return res.status(500).json({ message: 'Server Error' });
        }
    });
}
exports.AuthController = AuthController;
//# sourceMappingURL=authController.js.map
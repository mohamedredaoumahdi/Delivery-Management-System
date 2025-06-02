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
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jwt = __importStar(require("jsonwebtoken"));
const uuid_1 = require("uuid");
const database_1 = require("@/config/database");
const config_1 = require("@/config/config");
const appError_1 = require("@/utils/appError");
const catchAsync_1 = require("@/utils/catchAsync");
const emailService_1 = require("@/services/emailService");
class AuthController {
    generateTokens(userId, role) {
        const accessToken = jwt.sign({ userId, role }, config_1.config.jwtSecret, { expiresIn: config_1.config.jwtExpiresIn });
        const refreshToken = jwt.sign({ userId, role, tokenId: (0, uuid_1.v4)() }, config_1.config.jwtRefreshSecret, { expiresIn: config_1.config.jwtRefreshExpiresIn });
        return { accessToken, refreshToken };
    }
    register = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { email, password, name, role = 'CUSTOMER' } = req.body;
        const existingUser = await database_1.prisma.user.findUnique({
            where: { email },
        });
        if (existingUser) {
            return next(new appError_1.AppError('User with this email already exists', 400));
        }
        const passwordHash = await bcryptjs_1.default.hash(password, 12);
        const user = await database_1.prisma.user.create({
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
        const { accessToken, refreshToken } = this.generateTokens(user.id, user.role);
        await database_1.prisma.refreshToken.create({
            data: {
                token: refreshToken,
                userId: user.id,
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            },
        });
        try {
            await emailService_1.EmailService.sendWelcomeEmail(user.email, user.name);
        }
        catch (error) {
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
    login = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { email, password } = req.body;
        const user = await database_1.prisma.user.findUnique({
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
        if (!user) {
            return next(new appError_1.AppError('No account found with this email address. Please check your email or sign up for a new account.', 404));
        }
        if (!(await bcryptjs_1.default.compare(password, user.passwordHash))) {
            return next(new appError_1.AppError('Incorrect password. Please check your password and try again.', 401));
        }
        if (!user.isActive) {
            return next(new appError_1.AppError('Your account has been deactivated. Please contact support for assistance.', 403));
        }
        const { accessToken, refreshToken } = this.generateTokens(user.id, user.role);
        await database_1.prisma.refreshToken.create({
            data: {
                token: refreshToken,
                userId: user.id,
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            },
        });
        await database_1.prisma.user.update({
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
    refreshToken = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            return next(new appError_1.AppError('Refresh token is required', 400));
        }
        try {
            const decoded = jwt.verify(refreshToken, config_1.config.jwtRefreshSecret);
            const storedToken = await database_1.prisma.refreshToken.findFirst({
                where: {
                    token: refreshToken,
                    userId: decoded.userId,
                    expiresAt: { gt: new Date() },
                },
            });
            if (!storedToken) {
                return next(new appError_1.AppError('Invalid refresh token', 401));
            }
            const { accessToken: newAccessToken, refreshToken: newRefreshToken } = this.generateTokens(decoded.userId, decoded.role);
            await database_1.prisma.refreshToken.delete({
                where: { id: storedToken.id },
            });
            await database_1.prisma.refreshToken.create({
                data: {
                    token: newRefreshToken,
                    userId: decoded.userId,
                    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
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
        }
        catch (error) {
            return next(new appError_1.AppError('Invalid refresh token', 401));
        }
    });
    logout = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { refreshToken } = req.body;
        if (refreshToken) {
            await database_1.prisma.refreshToken.deleteMany({
                where: {
                    token: refreshToken,
                    userId: req.user.id,
                },
            });
        }
        res.json({
            status: 'success',
            message: 'Logged out successfully',
        });
    });
    forgotPassword = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { email } = req.body;
        const user = await database_1.prisma.user.findUnique({
            where: { email },
        });
        if (!user) {
            return next(new appError_1.AppError('No user found with this email address', 404));
        }
        const resetToken = jwt.sign({ userId: user.id }, config_1.config.jwtSecret, { expiresIn: '1h' });
        await database_1.prisma.passwordResetToken.create({
            data: {
                tokenHash: await bcryptjs_1.default.hash(resetToken, 12),
                userId: user.id,
                expiresAt: new Date(Date.now() + 60 * 60 * 1000),
            },
        });
        try {
            await emailService_1.EmailService.sendPasswordResetEmail(user.email, resetToken);
        }
        catch (error) {
            console.error('Failed to send password reset email:', error);
            return next(new appError_1.AppError('Failed to send password reset email', 500));
        }
        res.json({
            status: 'success',
            message: 'Password reset instructions sent to your email',
        });
    });
    resetPassword = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { token, password } = req.body;
        try {
            const decoded = jwt.verify(token, config_1.config.jwtSecret);
            const resetToken = await database_1.prisma.passwordResetToken.findFirst({
                where: {
                    tokenHash: await bcryptjs_1.default.hash(token, 12),
                    userId: decoded.userId,
                    expiresAt: { gt: new Date() },
                },
            });
            if (!resetToken) {
                return next(new appError_1.AppError('Invalid or expired reset token', 400));
            }
            const passwordHash = await bcryptjs_1.default.hash(password, 12);
            await database_1.prisma.user.update({
                where: { id: decoded.userId },
                data: { passwordHash },
            });
            await database_1.prisma.passwordResetToken.delete({
                where: { id: resetToken.id },
            });
            res.json({
                status: 'success',
                message: 'Password reset successful',
            });
        }
        catch (error) {
            return next(new appError_1.AppError('Invalid reset token', 400));
        }
    });
    verifyEmail = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { token } = req.params;
        try {
            const decoded = jwt.verify(token, config_1.config.jwtSecret);
            const verificationToken = await database_1.prisma.emailVerificationToken.findFirst({
                where: {
                    token,
                    userId: decoded.userId,
                    expiresAt: { gt: new Date() },
                },
            });
            if (!verificationToken) {
                return next(new appError_1.AppError('Invalid or expired verification token', 400));
            }
            await database_1.prisma.user.update({
                where: { id: decoded.userId },
                data: { isEmailVerified: true },
            });
            await database_1.prisma.emailVerificationToken.delete({
                where: { id: verificationToken.id },
            });
            res.json({
                status: 'success',
                message: 'Email verified successfully',
            });
        }
        catch (error) {
            return next(new appError_1.AppError('Invalid verification token', 400));
        }
    });
    getCurrentUser = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const user = await database_1.prisma.user.findUnique({
            where: { id: req.user.id },
            select: {
                id: true,
                email: true,
                name: true,
                phone: true,
                profilePicture: true,
                role: true,
                isEmailVerified: true,
                isPhoneVerified: true,
                isActive: true,
                lastLoginAt: true,
                createdAt: true,
                updatedAt: true,
            },
        });
        if (!user) {
            return next(new appError_1.AppError('User not found', 404));
        }
        res.json({
            status: 'success',
            data: user,
        });
    });
}
exports.AuthController = AuthController;
//# sourceMappingURL=authController.js.map
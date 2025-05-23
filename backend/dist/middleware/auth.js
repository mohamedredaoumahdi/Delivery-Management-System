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
exports.AuthController = exports.requireRole = exports.auth = void 0;
const jwt = __importStar(require("jsonwebtoken"));
const config_1 = require("@/config/config");
const database_1 = require("@/config/database");
const appError_1 = require("@/utils/appError");
const auth = async (req, res, next) => {
    try {
        const token = req.header('Authorization')?.replace('Bearer ', '');
        if (!token) {
            throw new appError_1.AppError('Access denied. No token provided.', 401);
        }
        const decoded = jwt.verify(token, config_1.config.jwtSecret);
        const user = await database_1.prisma.user.findUnique({
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
            throw new appError_1.AppError('Token is not valid.', 401);
        }
        if (!user.isActive) {
            throw new appError_1.AppError('Account has been deactivated.', 401);
        }
        req.user = user;
        next();
    }
    catch (error) {
        if (error instanceof jwt.JsonWebTokenError) {
            next(new appError_1.AppError('Token is not valid.', 401));
        }
        else {
            next(error);
        }
    }
};
exports.auth = auth;
const requireRole = (roles) => {
    return (req, res, next) => {
        if (!req.user) {
            throw new appError_1.AppError('Authentication required.', 401);
        }
        if (!roles.includes(req.user.role)) {
            throw new appError_1.AppError('Insufficient permissions.', 403);
        }
        next();
    };
};
exports.requireRole = requireRole;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const uuid_1 = require("uuid");
const catchAsync_1 = require("@/utils/catchAsync");
const redis_1 = require("@/config/redis");
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
        if (!user || !user.isActive) {
            return next(new appError_1.AppError('Invalid email or password', 401));
        }
        const isPasswordValid = await bcryptjs_1.default.compare(password, user.passwordHash);
        if (!isPasswordValid) {
            return next(new appError_1.AppError('Invalid email or password', 401));
        }
        await database_1.prisma.user.update({
            where: { id: user.id },
            data: { lastLoginAt: new Date() },
        });
        const { accessToken, refreshToken } = this.generateTokens(user.id, user.role);
        await database_1.prisma.refreshToken.create({
            data: {
                token: refreshToken,
                userId: user.id,
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            },
        });
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
    refreshToken = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            return next(new appError_1.AppError('Refresh token is required', 400));
        }
        let decoded;
        try {
            decoded = jwt.verify(refreshToken, config_1.config.jwtRefreshSecret);
        }
        catch (error) {
            return next(new appError_1.AppError('Invalid refresh token', 401));
        }
        const storedToken = await database_1.prisma.refreshToken.findUnique({
            where: { token: refreshToken },
            include: { user: true },
        });
        if (!storedToken || storedToken.expiresAt < new Date()) {
            return next(new appError_1.AppError('Refresh token is invalid or expired', 401));
        }
        const { accessToken, refreshToken: newRefreshToken } = this.generateTokens(storedToken.user.id, storedToken.user.role);
        await database_1.prisma.refreshToken.delete({
            where: { token: refreshToken },
        });
        await database_1.prisma.refreshToken.create({
            data: {
                token: newRefreshToken,
                userId: storedToken.user.id,
                expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
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
    logout = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { refreshToken } = req.body;
        if (refreshToken) {
            await database_1.prisma.refreshToken.deleteMany({
                where: { token: refreshToken },
            });
        }
        if (req.user) {
            await redis_1.SessionService.deleteSession(req.user.id);
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
            return res.json({
                status: 'success',
                message: 'If an account with that email exists, we sent you a password reset link.',
            });
        }
        const resetToken = (0, uuid_1.v4)();
        const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000);
        await redis_1.SessionService.setSession(`password-reset:${resetToken}`, { userId: user.id, email: user.email }, 3600);
        try {
            await emailService_1.EmailService.sendPasswordResetEmail(user.email, user.name, resetToken);
        }
        catch (error) {
            console.error('Failed to send password reset email:', error);
            return next(new appError_1.AppError('Failed to send password reset email', 500));
        }
        res.json({
            status: 'success',
            message: 'If an account with that email exists, we sent you a password reset link.',
        });
    });
    resetPassword = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { token, newPassword } = req.body;
        const resetData = await redis_1.SessionService.getSession(`password-reset:${token}`);
        if (!resetData) {
            return next(new appError_1.AppError('Invalid or expired reset token', 400));
        }
        const passwordHash = await bcryptjs_1.default.hash(newPassword, 12);
        await database_1.prisma.user.update({
            where: { id: resetData.userId },
            data: { passwordHash },
        });
        await redis_1.SessionService.deleteSession(`password-reset:${token}`);
        await database_1.prisma.refreshToken.deleteMany({
            where: { userId: resetData.userId },
        });
        res.json({
            status: 'success',
            message: 'Password reset successfully',
        });
    });
    verifyEmail = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { token } = req.body;
        res.json({
            status: 'success',
            message: 'Email verified successfully',
        });
    });
}
exports.AuthController = AuthController;
//# sourceMappingURL=auth.js.map
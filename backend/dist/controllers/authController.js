"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const client_1 = require("@prisma/client");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const express_validator_1 = require("express-validator");
const uuid_1 = require("uuid");
const sendEmail_1 = __importDefault(require("@/utils/sendEmail"));
const prisma = new client_1.PrismaClient();
const generateToken = (id) => {
    return jsonwebtoken_1.default.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN,
    });
};
const generateRefreshToken = (userId) => {
    const token = jsonwebtoken_1.default.sign({ userId }, process.env.JWT_REFRESH_SECRET, {
        expiresIn: process.env.JWT_REFRESH_EXPIRES_IN,
    });
    return token;
};
class AuthController {
    async register(req, res, next) {
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
                return res.status(400).json({ message: 'User already exists' });
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
            if (user) {
                const verificationToken = (0, uuid_1.v4)();
                const verificationExpiresAt = new Date(Date.now() + 3600000 * 24);
                await prisma.emailVerificationToken.create({
                    data: {
                        token: verificationToken,
                        userId: user.id,
                        expiresAt: verificationExpiresAt,
                    },
                });
                const verificationUrl = `${process.env.FRONTEND_URL}/verify-email?token=${verificationToken}`;
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
                res.status(201).json({
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    token: generateToken(user.id),
                });
            }
            else {
                res.status(400).json({ message: 'Invalid user data' });
            }
        }
        catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server Error' });
        }
    }
    async login(req, res, next) {
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
            if (user && (await bcryptjs_1.default.compare(password, user.passwordHash))) {
                res.json({
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    token: generateToken(user.id),
                });
            }
            else {
                res.status(401).json({ message: 'Invalid credentials' });
            }
        }
        catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server Error' });
        }
    }
    async refreshToken(req, res, next) {
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
            const newAccessToken = generateToken(user.id);
            res.json({
                accessToken: newAccessToken,
            });
        }
        catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server Error' });
        }
    }
    async logout(req, res, next) {
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
            res.status(200).json({ message: 'Logged out successfully' });
        }
        catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server Error' });
        }
    }
    async forgotPassword(req, res, next) {
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
            const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
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
            res.status(200).json({ message: 'If a user with that email exists, a password reset link has been sent.' });
        }
        catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server Error' });
        }
    }
    async resetPassword(req, res, next) {
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
            res.status(200).json({ message: 'Password reset successfully' });
        }
        catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server Error' });
        }
    }
    async verifyEmail(req, res, next) {
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
            res.status(200).json({ message: 'Email verified successfully' });
        }
        catch (error) {
            console.error(error);
            res.status(500).json({ message: 'Server Error' });
        }
    }
}
exports.AuthController = AuthController;
//# sourceMappingURL=authController.js.map
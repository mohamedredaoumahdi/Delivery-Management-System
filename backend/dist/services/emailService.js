"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.EmailService = void 0;
const config_1 = require("@/config/config");
const sendEmail_1 = __importDefault(require("@/utils/sendEmail"));
class EmailService {
    static async sendWelcomeEmail(email, name) {
        const subject = 'Welcome to Our Platform';
        const message = `Hello ${name},\n\nWelcome to our platform! We're excited to have you on board.\n\nBest regards,\nThe Team`;
        await (0, sendEmail_1.default)({
            email,
            subject,
            message,
        });
    }
    static async sendPasswordResetEmail(email, token) {
        const resetUrl = `${config_1.config.frontendUrl}/reset-password?token=${token}`;
        const subject = 'Password Reset Request';
        const message = `You requested a password reset. Please use the following link to reset your password: ${resetUrl}\n\nIf you did not request this, please ignore this email.`;
        await (0, sendEmail_1.default)({
            email,
            subject,
            message,
        });
    }
}
exports.EmailService = EmailService;
//# sourceMappingURL=emailService.js.map
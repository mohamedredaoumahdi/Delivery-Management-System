"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateConfig = exports.config = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
dotenv_1.default.config();
const requiredEnvVars = [
    'DATABASE_URL',
    'JWT_SECRET',
    'JWT_REFRESH_SECRET'
];
const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
if (missingVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
}
exports.config = {
    nodeEnv: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT || '3000', 10),
    databaseUrl: process.env.DATABASE_URL,
    redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
    jwtSecret: process.env.JWT_SECRET,
    jwtRefreshSecret: process.env.JWT_REFRESH_SECRET,
    jwtExpiresIn: process.env.JWT_EXPIRES_IN || '15m',
    jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
    smtpHost: process.env.SMTP_HOST || 'smtp.gmail.com',
    smtpPort: parseInt(process.env.SMTP_PORT || '587', 10),
    smtpUser: process.env.SMTP_USER || '',
    smtpPassword: process.env.SMTP_PASSWORD || '',
    fromEmail: process.env.FROM_EMAIL || 'noreply@deliverysystem.com',
    fromName: process.env.FROM_NAME || 'Delivery System',
    uploadDir: process.env.UPLOAD_DIR || 'uploads',
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE || '10485760', 10),
    allowedImageTypes: (process.env.ALLOWED_IMAGE_TYPES || 'image/jpeg,image/png,image/webp').split(','),
    apiVersion: process.env.API_VERSION || 'v1',
    corsOrigin: (process.env.CORS_ORIGIN || '*').split(','),
    rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
    logLevel: process.env.LOG_LEVEL || 'info',
    logFile: process.env.LOG_FILE || path_1.default.join(process.cwd(), 'logs', 'app.log'),
    googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY,
    stripeSecretKey: process.env.STRIPE_SECRET_KEY,
    stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
    firebaseServerKey: process.env.FIREBASE_SERVER_KEY,
    twilioAccountSid: process.env.TWILIO_ACCOUNT_SID,
    twilioAuthToken: process.env.TWILIO_AUTH_TOKEN,
    twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER,
    socketCorsOrigin: (process.env.SOCKET_CORS_ORIGIN || 'http://localhost:3000').split(','),
    enableSwagger: process.env.ENABLE_SWAGGER === 'true',
    enableCompression: process.env.ENABLE_COMPRESSION !== 'false',
    enableMorganLogging: process.env.ENABLE_MORGAN_LOGGING !== 'false',
};
const validateConfig = () => {
    if (!Number.isInteger(exports.config.port) || exports.config.port < 1 || exports.config.port > 65535) {
        throw new Error('Invalid port number');
    }
    if (!['development', 'production', 'test'].includes(exports.config.nodeEnv)) {
        throw new Error('Invalid NODE_ENV value');
    }
    if (exports.config.maxFileSize < 1024 * 1024) {
        throw new Error('MAX_FILE_SIZE too small (minimum 1MB)');
    }
};
exports.validateConfig = validateConfig;
(0, exports.validateConfig)();
//# sourceMappingURL=config.js.map
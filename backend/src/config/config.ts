// src/config/config.ts
import dotenv from 'dotenv';
import path from 'path';

// Load environment variables
dotenv.config();

interface Config {
  // Environment
  nodeEnv: string;
  port: number;
  
  // Database
  databaseUrl: string;
  
  // Redis
  redisUrl: string;
  
  // JWT
  jwtSecret: string;
  jwtRefreshSecret: string;
  jwtExpiresIn: string;
  jwtRefreshExpiresIn: string;
  
  // Email
  smtpHost: string;
  smtpPort: number;
  smtpUser: string;
  smtpPassword: string;
  fromEmail: string;
  fromName: string;
  
  // File Upload
  uploadDir: string;
  maxFileSize: number;
  allowedImageTypes: string[];
  
  // API
  apiVersion: string;
  corsOrigin: string[];
  
  // Rate Limiting
  rateLimitWindowMs: number;
  rateLimitMaxRequests: number;
  
  // Logging
  logLevel: string;
  logFile: string;
  
  // Third-party Services
  googleMapsApiKey?: string;
  stripeSecretKey?: string;
  stripeWebhookSecret?: string;
  firebaseServerKey?: string;
  
  // SMS
  twilioAccountSid?: string;
  twilioAuthToken?: string;
  twilioPhoneNumber?: string;
  
  // Socket.io
  socketCorsOrigin: string[];
  
  // Feature Flags
  enableSwagger: boolean;
  enableCompression: boolean;
  enableMorganLogging: boolean;
}

const requiredEnvVars = [
  'DATABASE_URL',
  'JWT_SECRET',
  'JWT_REFRESH_SECRET'
];

// Validate required environment variables
const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
if (missingVars.length > 0) {
  throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
}

export const config: Config = {
  // Environment
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  
  // Database
  databaseUrl: process.env.DATABASE_URL!,
  
  // Redis
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
  
  // JWT
  jwtSecret: process.env.JWT_SECRET!,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET!,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  
  // Email
  smtpHost: process.env.SMTP_HOST || 'smtp.gmail.com',
  smtpPort: parseInt(process.env.SMTP_PORT || '587', 10),
  smtpUser: process.env.SMTP_USER || '',
  smtpPassword: process.env.SMTP_PASSWORD || '',
  fromEmail: process.env.FROM_EMAIL || 'noreply@deliverysystem.com',
  fromName: process.env.FROM_NAME || 'Delivery System',
  
  // File Upload
  uploadDir: process.env.UPLOAD_DIR || 'uploads',
  maxFileSize: parseInt(process.env.MAX_FILE_SIZE || '10485760', 10), // 10MB
  allowedImageTypes: (process.env.ALLOWED_IMAGE_TYPES || 'image/jpeg,image/png,image/webp').split(','),
  
  // API
  apiVersion: process.env.API_VERSION || 'v1',
  corsOrigin: (process.env.CORS_ORIGIN || '*').split(','),
  
  // Rate Limiting
  rateLimitWindowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10), // 15 minutes
  rateLimitMaxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
  
  // Logging
  logLevel: process.env.LOG_LEVEL || 'info',
  logFile: process.env.LOG_FILE || path.join(process.cwd(), 'logs', 'app.log'),
  
  // Third-party Services
  googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY,
  stripeSecretKey: process.env.STRIPE_SECRET_KEY,
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
  firebaseServerKey: process.env.FIREBASE_SERVER_KEY,
  
  // SMS
  twilioAccountSid: process.env.TWILIO_ACCOUNT_SID,
  twilioAuthToken: process.env.TWILIO_AUTH_TOKEN,
  twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER,
  
  // Socket.io
  socketCorsOrigin: (process.env.SOCKET_CORS_ORIGIN || 'http://localhost:3000').split(','),
  
  // Feature Flags
  enableSwagger: process.env.ENABLE_SWAGGER === 'true',
  enableCompression: process.env.ENABLE_COMPRESSION !== 'false',
  enableMorganLogging: process.env.ENABLE_MORGAN_LOGGING !== 'false',
};

// Validate configuration
export const validateConfig = (): void => {
  if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) {
    throw new Error('Invalid port number');
  }
  
  if (!['development', 'production', 'test'].includes(config.nodeEnv)) {
    throw new Error('Invalid NODE_ENV value');
  }
  
  if (config.maxFileSize < 1024 * 1024) { // 1MB minimum
    throw new Error('MAX_FILE_SIZE too small (minimum 1MB)');
  }
};

// Run validation
validateConfig();
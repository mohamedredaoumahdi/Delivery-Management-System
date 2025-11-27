import rateLimit from 'express-rate-limit';
import { config } from '@/config/config';

export const rateLimiter = rateLimit({
  windowMs: config.rateLimitWindowMs,
  max: config.rateLimitMaxRequests,
  message: {
    status: 'error',
    message: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip global rate limiting for:
    // - delivery, shop, auth, and user routes (they have their own limiters or are authenticated)
    // - static uploads (images, files) so UI assets are never throttled
    return (
      req.path.startsWith('/api/delivery') ||
      req.path.startsWith('/api/shops') ||
      req.path.startsWith('/api/auth') ||
      req.path.startsWith('/api/users') ||
      req.path.startsWith('/uploads')
    );
  },
});

// Auth-specific rate limiter (more restrictive in production, lenient in development)
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 5 : 100, // More lenient in development
  message: {
    status: 'error',
    message: 'Too many authentication attempts, please try again later.',
  },
  skipSuccessfulRequests: true,
});

// Delivery-specific rate limiter (more lenient for auto-refresh)
export const deliveryRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60, // limit each IP to 60 requests per minute (1 per second)
  message: {
    status: 'error',
    message: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for status endpoints (they're called less frequently)
    return req.path.includes('/status');
  },
});

// Shop-specific rate limiter (more lenient for browsing)
export const shopRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 120, // limit each IP to 120 requests per minute (2 per second)
  message: {
    status: 'error',
    message: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
}); 
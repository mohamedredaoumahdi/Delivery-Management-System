import { Router } from 'express';
import { AuthController } from '@/controllers/authController';
import { validateRequest } from '@/middleware/validation';
import { loginSchema, registerSchema } from '@/validators/authValidators';
import { rateLimiter } from '@/middleware/rateLimiter';

const router = Router();
const authController = new AuthController();

// Apply rate limiting to auth routes
router.use(rateLimiter);

router.post('/register', validateRequest(registerSchema), authController.register);
router.post('/login', validateRequest(loginSchema), authController.login);
router.post('/refresh', authController.refreshToken);
router.post('/logout', authController.logout);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.post('/verify-email', authController.verifyEmail);

export default router; 
import { Router } from 'express';
import { DeliveryController } from '@/controllers/deliveryController';
import { auth } from '@/middleware/auth';
import { requireRole } from '@/middleware/requireRole';
import { validateRequest } from '@/middleware/validation';
import { updateLocationSchema } from '@/validators/deliveryValidators';
import { deliveryRateLimiter } from '@/middleware/rateLimiter';

const router = Router();
const deliveryController = new DeliveryController();

// Apply lenient rate limiter for delivery endpoints (allows auto-refresh)
router.use(deliveryRateLimiter);

// All delivery routes require authentication and delivery role
router.use(auth);
router.use(requireRole(['DELIVERY']));

// Order management
router.get('/orders', deliveryController.getAssignedOrders);
router.get('/orders/available', deliveryController.getAvailableOrders);
router.patch('/orders/:id/accept', deliveryController.acceptOrder);
router.patch('/orders/:id/pickup', deliveryController.markPickedUp);
router.patch('/orders/:id/delivered', deliveryController.markDelivered);

// Location tracking
router.patch('/orders/:id/location', validateRequest(updateLocationSchema), deliveryController.updateLocation);

// Status management
router.post('/status/online', deliveryController.goOnline);
router.post('/status/offline', deliveryController.goOffline);

// Performance
router.get('/stats', deliveryController.getDeliveryStats);
router.get('/earnings', deliveryController.getEarnings);

export default router; 
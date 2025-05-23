import { Router } from 'express';
import { DeliveryController } from '@/controllers/deliveryController';
import { auth } from '@/middleware/auth';
import { requireRole } from '@/middleware/requireRole';
import { validateRequest } from '@/middleware/validation';
import { updateLocationSchema } from '@/validators/deliveryValidators';

const router = Router();
const deliveryController = new DeliveryController();

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

// Performance
router.get('/stats', deliveryController.getDeliveryStats);
router.get('/earnings', deliveryController.getEarnings);

export default router; 
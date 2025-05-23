import { Router } from 'express';
import { OrderController } from '@/controllers/orderController';
import { auth } from '@/middleware/auth';
import { validateRequest } from '@/middleware/validation';
import { createOrderSchema, updateOrderSchema } from '@/validators/orderValidators';

const router = Router();
const orderController = new OrderController();

// All order routes require authentication
router.use(auth);

router.post('/', validateRequest(createOrderSchema), orderController.createOrder);
router.get('/', orderController.getUserOrders);
router.get('/:id', orderController.getOrderById);
router.patch('/:id/cancel', orderController.cancelOrder);
router.patch('/:id/tip', validateRequest(updateOrderSchema), orderController.updateTip);
router.get('/:id/track', orderController.trackOrder);

export default router; 
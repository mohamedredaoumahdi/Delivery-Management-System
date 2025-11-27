import { Router } from 'express';
import { OrderController } from '@/controllers/orderController';
import { auth } from '@/middleware/auth';
import { validateRequest } from '@/middleware/validation';
import { createOrderSchema, updateOrderSchema } from '@/validators/orderValidators';
import { catchAsync } from '@/utils/catchAsync';

const router = Router();
const orderController = new OrderController();

// All order routes require authentication
router.use(auth);

router.post('/', validateRequest(createOrderSchema), catchAsync(orderController.createOrder));
router.post('/confirm-payment', catchAsync(orderController.confirmPayment));
router.post('/refund', catchAsync(orderController.processRefund));
router.get('/', catchAsync(orderController.getUserOrders));
router.get('/:id', catchAsync(orderController.getOrderById));
router.patch('/:id/cancel', catchAsync(orderController.cancelOrder));
router.patch('/:id/tip', validateRequest(updateOrderSchema), catchAsync(orderController.updateTip));
router.get('/:id/track', catchAsync(orderController.trackOrder));

export default router; 
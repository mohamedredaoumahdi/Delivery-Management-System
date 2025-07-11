import express from 'express';
import { PaymentMethodController } from '../controllers/paymentMethodController';
import { auth } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { catchAsync } from '../utils/catchAsync';
import { 
  createPaymentMethodSchema, 
  updatePaymentMethodSchema 
} from '../validators/paymentMethodValidators';

const router = express.Router();
const paymentMethodController = new PaymentMethodController();

// All payment method routes require authentication
router.use(auth);

// GET /api/users/payment-methods - Get all payment methods for user
router.get(
  '/',
  catchAsync(paymentMethodController.getPaymentMethods)
);

// POST /api/users/payment-methods - Create a new payment method
router.post(
  '/',
  validateRequest(createPaymentMethodSchema),
  catchAsync(paymentMethodController.createPaymentMethod)
);

// PUT /api/users/payment-methods/:paymentMethodId - Update a payment method
router.put(
  '/:paymentMethodId',
  validateRequest(updatePaymentMethodSchema),
  catchAsync(paymentMethodController.updatePaymentMethod)
);

// DELETE /api/users/payment-methods/:paymentMethodId - Delete a payment method
router.delete(
  '/:paymentMethodId',
  catchAsync(paymentMethodController.deletePaymentMethod)
);

// PUT /api/users/payment-methods/:paymentMethodId/default - Set as default payment method
router.put(
  '/:paymentMethodId/default',
  catchAsync(paymentMethodController.setDefaultPaymentMethod)
);

export default router; 
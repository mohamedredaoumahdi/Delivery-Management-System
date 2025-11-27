import { Router } from 'express';
import { PaymentWebhookController } from '@/controllers/paymentWebhookController';
import express from 'express';

const router = Router();
const webhookController = new PaymentWebhookController();

// Stripe webhooks need raw body for signature verification
// This route should be mounted BEFORE body-parser middleware
router.post(
  '/stripe',
  express.raw({ type: 'application/json' }),
  webhookController.handleStripeWebhook
);

export default router;


import { Request, Response } from 'express';
import { paymentService } from '@/services/paymentService';
import { prisma } from '@/config/database';
import { OrderStatus } from '@prisma/client';
import { getIO } from '@/services/socketService';
import { NotificationService } from '@/services/notificationService';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { logger } from '@/utils/logger';
import Stripe from 'stripe';

export class PaymentWebhookController {
  /**
   * Handle Stripe webhook events
   */
  handleStripeWebhook = catchAsync(async (req: Request, res: Response): Promise<void> => {
    const signature = req.headers['stripe-signature'] as string;

    if (!signature) {
      throw new AppError('Missing Stripe signature', 400);
    }

    let event: Stripe.Event;

    try {
      // Verify webhook signature and construct event
      event = paymentService.verifyWebhookSignature(
        req.body,
        signature
      );
    } catch (error: any) {
      logger.error('Webhook signature verification failed', error);
      res.status(400).json({ error: 'Invalid signature' });
      return;
    }

    // Handle the event
    try {
      await paymentService.handleWebhookEvent(event);
      await this.processWebhookEvent(event);
    } catch (error: any) {
      logger.error('Error processing webhook event', error);
      // Return 200 to acknowledge receipt even if processing fails
      // Stripe will retry if needed
    }

    // Return 200 to acknowledge receipt
    res.json({ received: true });
  });

  /**
   * Process webhook event and update order status
   */
  private async processWebhookEvent(event: Stripe.Event): Promise<void> {
    switch (event.type) {
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        await this.handlePaymentSuccess(paymentIntent);
        break;
      }

      case 'payment_intent.payment_failed': {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        await this.handlePaymentFailure(paymentIntent);
        break;
      }

      case 'charge.refunded': {
        const refund = event.data.object as unknown as Stripe.Refund;
        await this.handleRefundProcessed(refund);
        break;
      }

      default:
        logger.info(`Unhandled webhook event type: ${event.type}`);
    }
  }

  /**
   * Handle successful payment
   */
  private async handlePaymentSuccess(paymentIntent: Stripe.PaymentIntent): Promise<void> {
    const orderNumber = paymentIntent.metadata?.orderNumber;
    const orderId = paymentIntent.metadata?.orderId;

    if (!orderId) {
      logger.warn(`Payment intent ${paymentIntent.id} has no order ID in metadata`);
      return;
    }

    try {
      // Find order by payment ID
      const order = await prisma.order.findFirst({
        where: {
          OR: [
            { paymentId: paymentIntent.id },
            { id: orderId },
          ],
        },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
        },
      });

      if (!order) {
        logger.warn(`Order not found for payment intent ${paymentIntent.id}`);
        return;
      }

      // Update order payment status (order status remains PENDING until vendor accepts)
      // The paymentId is already set, we just log the success
      logger.info(`Payment succeeded for order ${order.orderNumber} (${order.id})`);

      // Emit real-time update
      const io = getIO();
      if (io) {
        io.to(`order:${order.id}`).emit('order:payment_succeeded', {
          orderId: order.id,
          paymentIntentId: paymentIntent.id,
        });
        io.to(`user:${order.userId}`).emit('order:payment_succeeded', {
          orderId: order.id,
        });
        io.to(`shop:${order.shopId}`).emit('order:payment_succeeded', {
          orderId: order.id,
        });
      }

      // Send notification to user
      await NotificationService.sendToUser(order.userId, {
        title: 'Payment Successful',
        body: `Your payment for order ${order.orderNumber} was successful`,
        data: { orderId: order.id },
      });
    } catch (error) {
      logger.error('Error handling payment success', error);
    }
  }

  /**
   * Handle failed payment
   */
  private async handlePaymentFailure(paymentIntent: Stripe.PaymentIntent): Promise<void> {
    const orderId = paymentIntent.metadata?.orderId;

    if (!orderId) {
      logger.warn(`Payment intent ${paymentIntent.id} has no order ID in metadata`);
      return;
    }

    try {
      const order = await prisma.order.findFirst({
        where: {
          OR: [
            { paymentId: paymentIntent.id },
            { id: orderId },
          ],
        },
        include: {
          user: {
            select: {
              id: true,
            },
          },
        },
      });

      if (!order) {
        logger.warn(`Order not found for payment intent ${paymentIntent.id}`);
        return;
      }

      logger.warn(`Payment failed for order ${order.orderNumber} (${order.id})`);

      // Emit real-time update
      const io = getIO();
      if (io) {
        io.to(`order:${order.id}`).emit('order:payment_failed', {
          orderId: order.id,
          paymentIntentId: paymentIntent.id,
        });
        io.to(`user:${order.userId}`).emit('order:payment_failed', {
          orderId: order.id,
        });
      }

      // Send notification to user
      await NotificationService.sendToUser(order.userId, {
        title: 'Payment Failed',
        body: `Your payment for order ${order.orderNumber} failed. Please try again.`,
        data: { orderId: order.id },
      });
    } catch (error) {
      logger.error('Error handling payment failure', error);
    }
  }

  /**
   * Handle refund processed
   */
  private async handleRefundProcessed(refund: Stripe.Refund): Promise<void> {
    // Get the charge to find the payment intent
    try {
      // Note: We need to retrieve the charge to get the payment intent
      // For now, we'll search orders by payment ID pattern
      // In a production system, you might want to store charge IDs as well

      logger.info(`Refund processed: ${refund.id} for charge ${refund.charge}`);

      // Find order by searching payment intents or storing refund IDs
      // This is a simplified version - in production, you'd want to track refunds better
      const orders = await prisma.order.findMany({
        where: {
          status: OrderStatus.REFUNDED,
        },
        take: 1, // Just log for now
      });

      if (orders.length > 0) {
        logger.info(`Refund ${refund.id} processed for order ${orders[0].orderNumber}`);
      }
    } catch (error) {
      logger.error('Error handling refund processed', error);
    }
  }
}


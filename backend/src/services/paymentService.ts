import Stripe from 'stripe';
import { config } from '@/config/config';
import { getWhitelabelConfig } from '@/config/whitelabel';
import { AppError } from '@/utils/appError';
import { PaymentMethod } from '@prisma/client';
import { logger } from '@/utils/logger';

export interface PaymentIntentResult {
  paymentIntentId: string;
  clientSecret?: string;
  requiresAction?: boolean;
  status: 'requires_payment_method' | 'requires_confirmation' | 'requires_action' | 'processing' | 'succeeded' | 'requires_capture' | 'canceled';
}

export interface PaymentResult {
  success: boolean;
  paymentId: string;
  status: string;
  message?: string;
}

export interface RefundResult {
  success: boolean;
  refundId: string;
  amount: number;
  message?: string;
}

class PaymentService {
  private stripe: Stripe | null = null;
  private whitelabelConfig = getWhitelabelConfig();

  constructor() {
    this.initializeStripe();
  }

  private initializeStripe(): void {
    if (config.stripeSecretKey) {
      try {
        this.stripe = new Stripe(config.stripeSecretKey, {
          apiVersion: '2023-10-16',
        });
        logger.info('✅ Stripe payment service initialized');
      } catch (error) {
        logger.error('❌ Failed to initialize Stripe', error);
        this.stripe = null;
      }
    } else {
      logger.warn('⚠️ Stripe secret key not configured. Payment processing will be disabled.');
    }
  }

  /**
   * Create a payment intent for an order
   */
  async createPaymentIntent(
    amount: number,
    currency: string,
    orderId: string,
    orderNumber: string,
    paymentMethod: PaymentMethod,
    customerId?: string,
    paymentMethodId?: string
  ): Promise<PaymentIntentResult> {
    // Cash on delivery doesn't need payment processing
    if (paymentMethod === PaymentMethod.CASH_ON_DELIVERY) {
      return {
        paymentIntentId: `cod_${orderId}`,
        status: 'succeeded',
      };
    }

    // Check if payment gateway is enabled
    if (!this.whitelabelConfig.features.enablePaymentGateway) {
      throw new AppError('Payment gateway is not enabled', 400);
    }

    // Check if Stripe is configured
    if (!this.stripe) {
      throw new AppError('Payment processing is not configured. Please contact support.', 503);
    }

    const gateway = this.whitelabelConfig.payment.gateway.toLowerCase();

    if (gateway === 'stripe') {
      return await this.createStripePaymentIntent(
        amount,
        currency,
        orderId,
        orderNumber,
        customerId,
        paymentMethodId
      );
    } else if (gateway === 'paypal') {
      return await this.createPayPalPayment(
        amount,
        currency,
        orderId,
        orderNumber
      );
    } else if (gateway === 'razorpay') {
      return await this.createRazorpayPayment(
        amount,
        currency,
        orderId,
        orderNumber
      );
    } else {
      throw new AppError(`Unsupported payment gateway: ${gateway}`, 400);
    }
  }

  /**
   * Create Stripe payment intent
   */
  private async createStripePaymentIntent(
    amount: number,
    currency: string,
    orderId: string,
    orderNumber: string,
    customerId?: string,
    paymentMethodId?: string
  ): Promise<PaymentIntentResult> {
    if (!this.stripe) {
      throw new AppError('Stripe is not configured', 503);
    }

    try {
      // Convert amount to cents (Stripe uses smallest currency unit)
      const amountInCents = Math.round(amount * 100);

      const paymentIntentParams: Stripe.PaymentIntentCreateParams = {
        amount: amountInCents,
        currency: currency.toLowerCase(),
        metadata: {
          orderId,
          orderNumber,
        },
        description: `Order ${orderNumber}`,
        automatic_payment_methods: {
          enabled: true,
        },
      };

      // If customer ID is provided, attach it
      if (customerId) {
        paymentIntentParams.customer = customerId;
      }

      // If payment method ID is provided, attach it
      if (paymentMethodId) {
        paymentIntentParams.payment_method = paymentMethodId;
        paymentIntentParams.confirmation_method = 'manual';
        paymentIntentParams.confirm = false;
      }

      const paymentIntent = await this.stripe.paymentIntents.create(paymentIntentParams);

      return {
        paymentIntentId: paymentIntent.id,
        clientSecret: paymentIntent.client_secret || undefined,
        status: paymentIntent.status as PaymentIntentResult['status'],
        requiresAction: paymentIntent.status === 'requires_action',
      };
    } catch (error: any) {
      logger.error('Stripe payment intent creation failed', error);
      throw new AppError(
        error.message || 'Failed to create payment intent',
        error.statusCode || 500
      );
    }
  }

  /**
   * Confirm a payment intent (for 3D Secure and other actions)
   */
  async confirmPaymentIntent(
    paymentIntentId: string,
    paymentMethodId?: string
  ): Promise<PaymentResult> {
    if (!this.stripe) {
      throw new AppError('Stripe is not configured', 503);
    }

    try {
      const params: Stripe.PaymentIntentConfirmParams = {};
      if (paymentMethodId) {
        params.payment_method = paymentMethodId;
      }

      const paymentIntent = await this.stripe.paymentIntents.confirm(paymentIntentId, params);

      return {
        success: paymentIntent.status === 'succeeded',
        paymentId: paymentIntent.id,
        status: paymentIntent.status,
        message: paymentIntent.status === 'succeeded' ? 'Payment successful' : `Payment status: ${paymentIntent.status}`,
      };
    } catch (error: any) {
      logger.error('Stripe payment confirmation failed', error);
      throw new AppError(
        error.message || 'Failed to confirm payment',
        error.statusCode || 500
      );
    }
  }

  /**
   * Retrieve payment intent status
   */
  async getPaymentIntentStatus(paymentIntentId: string): Promise<PaymentResult> {
    // Cash on delivery
    if (paymentIntentId.startsWith('cod_')) {
      return {
        success: true,
        paymentId: paymentIntentId,
        status: 'succeeded',
        message: 'Cash on delivery - payment pending',
      };
    }

    if (!this.stripe) {
      throw new AppError('Stripe is not configured', 503);
    }

    try {
      const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentIntentId);

      return {
        success: paymentIntent.status === 'succeeded',
        paymentId: paymentIntent.id,
        status: paymentIntent.status,
        message: paymentIntent.status === 'succeeded' ? 'Payment successful' : `Payment status: ${paymentIntent.status}`,
      };
    } catch (error: any) {
      logger.error('Failed to retrieve payment intent', error);
      throw new AppError(
        error.message || 'Failed to retrieve payment status',
        error.statusCode || 500
      );
    }
  }

  /**
   * Process refund for an order
   */
  async processRefund(
    paymentId: string,
    amount: number,
    reason?: string
  ): Promise<RefundResult> {
    // Cash on delivery refunds are handled manually
    if (paymentId.startsWith('cod_')) {
      return {
        success: true,
        refundId: `refund_${Date.now()}`,
        amount,
        message: 'Refund processed (cash on delivery - manual processing required)',
      };
    }

    const gateway = this.whitelabelConfig.payment.gateway.toLowerCase();

    if (gateway === 'stripe') {
      return await this.processStripeRefund(paymentId, amount, reason);
    } else if (gateway === 'paypal') {
      return await this.processPayPalRefund(paymentId, amount, reason);
    } else if (gateway === 'razorpay') {
      return await this.processRazorpayRefund(paymentId, amount, reason);
    } else {
      throw new AppError(`Unsupported payment gateway: ${gateway}`, 400);
    }
  }

  /**
   * Create PayPal payment
   */
  private async createPayPalPayment(
    amount: number,
    currency: string,
    orderId: string,
    orderNumber: string
  ): Promise<PaymentIntentResult> {
    const paypalClientId = process.env.PAYPAL_CLIENT_ID;
    const paypalClientSecret = process.env.PAYPAL_CLIENT_SECRET;
    const paypalMode = process.env.PAYPAL_MODE || 'sandbox';
    
    if (!paypalClientId || !paypalClientSecret) {
      throw new AppError(
        'PayPal is not configured. Please set PAYPAL_CLIENT_ID and PAYPAL_CLIENT_SECRET environment variables.',
        503
      );
    }

    try {
      const paypalUrl = paypalMode === 'production' 
        ? 'https://api-m.paypal.com'
        : 'https://api-m.sandbox.paypal.com';

      const authResponse = await (await import('node-fetch')).default(
        `${paypalUrl}/v1/oauth2/token`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': `Basic ${Buffer.from(`${paypalClientId}:${paypalClientSecret}`).toString('base64')}`,
          },
          body: 'grant_type=client_credentials',
        }
      );

      if (!authResponse.ok) {
        throw new Error('Failed to get PayPal access token');
      }

      const authData: any = await authResponse.json();
      const accessToken = authData.access_token;

      const orderResponse = await (await import('node-fetch')).default(
        `${paypalUrl}/v2/checkout/orders`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
            'PayPal-Request-Id': orderId,
          },
          body: JSON.stringify({
            intent: 'CAPTURE',
            purchase_units: [
              {
                reference_id: orderId,
                description: `Order ${orderNumber}`,
                amount: {
                  currency_code: currency.toUpperCase(),
                  value: amount.toFixed(2),
                },
              },
            ],
          }),
        }
      );

      if (!orderResponse.ok) {
        const errorData = await orderResponse.json() as any;
        throw new Error(errorData?.message || 'Failed to create PayPal order');
      }

      const orderData: any = await orderResponse.json();
      
      return {
        paymentIntentId: orderData.id,
        clientSecret: orderData.id,
        status: 'requires_action',
        requiresAction: true,
      };
    } catch (error: any) {
      logger.error('PayPal payment creation failed', error);
      throw new AppError(
        error.message || 'Failed to create PayPal payment',
        500
      );
    }
  }

  /**
   * Create Razorpay payment
   */
  private async createRazorpayPayment(
    amount: number,
    currency: string,
    orderId: string,
    orderNumber: string
  ): Promise<PaymentIntentResult> {
    const razorpayKeyId = process.env.RAZORPAY_KEY_ID;
    const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET;

    if (!razorpayKeyId || !razorpayKeySecret) {
      throw new AppError(
        'Razorpay is not configured. Please set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET environment variables.',
        503
      );
    }

    try {
      const razorpay = await import('razorpay');
      const Razorpay = razorpay.default;
      
      const rzp = new Razorpay({
        key_id: razorpayKeyId,
        key_secret: razorpayKeySecret,
      });

      const amountInPaise = Math.round(amount * 100);

      const order = await rzp.orders.create({
        amount: amountInPaise,
        currency: currency.toUpperCase(),
        receipt: orderNumber,
        notes: {
          orderId,
          orderNumber,
        },
      });

      return {
        paymentIntentId: order.id,
        clientSecret: order.id,
        status: 'requires_action',
        requiresAction: true,
      };
    } catch (error: any) {
      logger.error('Razorpay payment creation failed', error);
      throw new AppError(
        error.message || 'Failed to create Razorpay payment',
        500
      );
    }
  }

  /**
   * Process Stripe refund
   */
  private async processStripeRefund(
    paymentId: string,
    amount: number,
    reason?: string
  ): Promise<RefundResult> {
    if (!this.stripe) {
      throw new AppError('Stripe is not configured', 503);
    }

    try {
      // First, retrieve the payment intent to get the charge ID
      const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentId);

      if (!paymentIntent.latest_charge) {
        throw new AppError('No charge found for this payment', 400);
      }

      const chargeId = paymentIntent.latest_charge as string;

      // Create refund
      const refundParams: Stripe.RefundCreateParams = {
        charge: chargeId,
        amount: Math.round(amount * 100), // Convert to cents
      };

      if (reason) {
        refundParams.reason = reason as Stripe.RefundCreateParams.Reason;
      }

      const refund = await this.stripe.refunds.create(refundParams);

      return {
        success: refund.status === 'succeeded' || refund.status === 'pending',
        refundId: refund.id,
        amount: refund.amount / 100, // Convert back from cents
        message: refund.status === 'succeeded' ? 'Refund processed successfully' : 'Refund is being processed',
      };
    } catch (error: any) {
      logger.error('Stripe refund failed', error);
      throw new AppError(
        error.message || 'Failed to process refund',
        error.statusCode || 500
      );
    }
  }

  /**
   * Process PayPal refund
   */
  private async processPayPalRefund(
    paymentId: string,
    amount: number,
    reason?: string
  ): Promise<RefundResult> {
    const paypalClientId = process.env.PAYPAL_CLIENT_ID;
    const paypalClientSecret = process.env.PAYPAL_CLIENT_SECRET;
    const paypalMode = process.env.PAYPAL_MODE || 'sandbox';
    
    if (!paypalClientId || !paypalClientSecret) {
      throw new AppError('PayPal is not configured', 503);
    }

    try {
      const paypalUrl = paypalMode === 'production' 
        ? 'https://api-m.paypal.com'
        : 'https://api-m.sandbox.paypal.com';

      // Get access token
      const authResponse = await (await import('node-fetch')).default(
        `${paypalUrl}/v1/oauth2/token`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': `Basic ${Buffer.from(`${paypalClientId}:${paypalClientSecret}`).toString('base64')}`,
          },
          body: 'grant_type=client_credentials',
        }
      );

      if (!authResponse.ok) {
        throw new Error('Failed to get PayPal access token');
      }

      const authData: any = await authResponse.json();
      const accessToken = authData.access_token;

      // Get capture ID from order
      const orderResponse = await (await import('node-fetch')).default(
        `${paypalUrl}/v2/checkout/orders/${paymentId}`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
          },
        }
      );

      if (!orderResponse.ok) {
        throw new Error('Failed to retrieve PayPal order');
      }

      const orderData: any = await orderResponse.json();
      const captureId = orderData.purchase_units?.[0]?.payments?.captures?.[0]?.id;

      if (!captureId) {
        throw new Error('No capture found for this PayPal order');
      }

      // Create refund
      const refundResponse = await (await import('node-fetch')).default(
        `${paypalUrl}/v2/payments/captures/${captureId}/refund`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            amount: {
              value: amount.toFixed(2),
              currency_code: this.whitelabelConfig.payment.currency.toUpperCase(),
            },
            note_to_payer: reason || 'Refund processed',
          }),
        }
      );

      if (!refundResponse.ok) {
        const errorData = await refundResponse.json() as any;
        throw new Error(errorData?.message || 'Failed to process PayPal refund');
      }

      const refundData: any = await refundResponse.json();

      return {
        success: refundData.status === 'COMPLETED' || refundData.status === 'PENDING',
        refundId: refundData.id,
        amount: parseFloat(refundData.amount.value),
        message: refundData.status === 'COMPLETED' ? 'Refund processed successfully' : 'Refund is being processed',
      };
    } catch (error: any) {
      logger.error('PayPal refund failed', error);
      throw new AppError(
        error.message || 'Failed to process PayPal refund',
        500
      );
    }
  }

  /**
   * Process Razorpay refund
   */
  private async processRazorpayRefund(
    paymentId: string,
    amount: number,
    reason?: string
  ): Promise<RefundResult> {
    const razorpayKeyId = process.env.RAZORPAY_KEY_ID;
    const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET;

    if (!razorpayKeyId || !razorpayKeySecret) {
      throw new AppError('Razorpay is not configured', 503);
    }

    try {
      const razorpay = await import('razorpay');
      const Razorpay = razorpay.default;
      
      const rzp = new Razorpay({
        key_id: razorpayKeyId,
        key_secret: razorpayKeySecret,
      });

      // Convert amount to paise (smallest currency unit for INR)
      const amountInPaise = Math.round(amount * 100);

      // Get payment details to find the payment ID
      // In Razorpay, paymentId might be an order ID, so we need to get the actual payment
      let actualPaymentId = paymentId;
      
      // If it's an order ID, get the first payment
      try {
        const payments = await rzp.orders.fetchPayments(paymentId);
        if (payments.items && payments.items.length > 0) {
          actualPaymentId = payments.items[0].id;
        }
      } catch {
        // If it fails, assume paymentId is already a payment ID
      }

      // Create refund
      const refund = await rzp.payments.refund(actualPaymentId, {
        amount: amountInPaise,
        notes: {
          reason: reason || 'Refund processed',
        },
      });

      return {
        success: refund.status === 'processed' || refund.status === 'pending',
        refundId: refund.id,
        amount: (refund.amount || 0) / 100, // Convert back from paise
        message: refund.status === 'processed' ? 'Refund processed successfully' : 'Refund is being processed',
      };
    } catch (error: any) {
      logger.error('Razorpay refund failed', error);
      throw new AppError(
        error.message || 'Failed to process Razorpay refund',
        500
      );
    }
  }

  /**
   * Handle Stripe webhook events
   */
  async handleWebhookEvent(event: Stripe.Event): Promise<void> {
    if (!this.stripe) {
      throw new AppError('Stripe is not configured', 503);
    }

    logger.info(`Processing Stripe webhook: ${event.type}`);

    switch (event.type) {
      case 'payment_intent.succeeded':
        // Payment was successful
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        logger.info(`Payment succeeded: ${paymentIntent.id}`);
        // Order status will be updated via the webhook handler in the controller
        break;

      case 'payment_intent.payment_failed':
        // Payment failed
        const failedPayment = event.data.object as Stripe.PaymentIntent;
        logger.warn(`Payment failed: ${failedPayment.id}`);
        break;

      case 'charge.refunded':
        // Refund was processed
        const refund = event.data.object as unknown as Stripe.Refund;
        logger.info(`Refund processed: ${refund.id}`);
        break;

      default:
        logger.info(`Unhandled webhook event type: ${event.type}`);
    }
  }

  /**
   * Verify webhook signature
   */
  verifyWebhookSignature(payload: string | Buffer, signature: string): Stripe.Event {
    if (!this.stripe) {
      throw new AppError('Stripe is not configured', 503);
    }

    if (!config.stripeWebhookSecret) {
      throw new AppError('Stripe webhook secret is not configured', 503);
    }

    try {
      return this.stripe.webhooks.constructEvent(
        payload,
        signature,
        config.stripeWebhookSecret
      );
    } catch (error: any) {
      logger.error('Webhook signature verification failed', error);
      throw new AppError('Invalid webhook signature', 400);
    }
  }
}

export const paymentService = new PaymentService();


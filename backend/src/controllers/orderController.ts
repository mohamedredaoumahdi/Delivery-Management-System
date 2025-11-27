import { Response } from 'express';
import { OrderStatus, PaymentMethod } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';
import { getIO } from '@/services/socketService';
import { NotificationService } from '@/services/notificationService';
import { RoutingService } from '@/services/routingService';
import { paymentService } from '@/services/paymentService';
import { getWhitelabelConfig } from '@/config/whitelabel';
import { logger } from '@/utils/logger';

import { prisma } from '@/config/database';

export class OrderController {
  async createOrder(req: AuthenticatedRequest, res: Response) {
    const { 
      items, 
      shopId, 
      deliveryAddress, 
      deliveryLatitude, 
      deliveryLongitude,
      deliveryInstructions,
      paymentMethod,
      tip = 0
    } = req.body;

    // Validate payment method
    const validPaymentMethods = Object.values(PaymentMethod);
    if (!validPaymentMethods.includes(paymentMethod)) {
      throw new AppError('Invalid payment method', 400);
    }

    // Fetch shop details
    const shop = await prisma.shop.findUnique({ 
      where: { id: shopId }, 
      select: { 
        name: true, 
        deliveryFee: true, 
        minimumOrderAmount: true,
        isActive: true,
        isOpen: true,
        hasDelivery: true,
        latitude: true,
        longitude: true,
        deliveryRadius: true
      } 
    });
    
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    if (!shop.isActive || !shop.isOpen) {
      throw new AppError('Shop is currently not accepting orders', 400);
    }

    if (!shop.hasDelivery) {
      throw new AppError('This shop does not offer delivery service', 400);
    }

    // Validate delivery address is within shop's delivery zone
    if (deliveryLatitude && deliveryLongitude && shop.latitude && shop.longitude) {
      const { haversineKm } = await import('@/utils/geo');
      const distanceKm = haversineKm(
        shop.latitude,
        shop.longitude,
        deliveryLatitude,
        deliveryLongitude
      );

      // Use shop's configured delivery radius (defaults to 10km if not set)
      const deliveryRadiusKm = shop.deliveryRadius || 10;
      
      if (distanceKm > deliveryRadiusKm) {
        throw new AppError(
          `Delivery address is ${distanceKm.toFixed(1)}km away. This shop only delivers within ${deliveryRadiusKm}km.`,
          400
        );
      }
    }

    // Fetch products to get their current prices and validate availability
    const productIds = items.map((item: any) => item.productId);
    const products = await prisma.product.findMany({
      where: {
        id: { in: productIds },
        shopId: shopId,
        isActive: true
      },
      select: {
        id: true,
        price: true,
        name: true,
        inStock: true,
        stockQuantity: true
      }
    });

    // Strong typing for product summaries
    type ProductSummary = {
      id: string;
      price: number;
      name: string;
      inStock: boolean;
      stockQuantity: number | null;
    };

    const productSummaries = products as unknown as ProductSummary[];
    // Create a map of product details for easy lookup
    const productMap: Map<string, ProductSummary> = new Map(
      productSummaries.map((p: ProductSummary) => [p.id, p])
    );

    // Validate all products exist, are from the same shop, and are in stock
    for (const item of items) {
      const product = productMap.get(item.productId);
      if (!product) {
        throw new AppError(`Product with ID ${item.productId} not found or not available`, 404);
      }
      if (!product.inStock || (product.stockQuantity !== null && product.stockQuantity < item.quantity)) {
        throw new AppError(`Product ${product.name} is out of stock or has insufficient quantity`, 400);
      }
    }

    // Calculate order totals
    const subtotal = items.reduce((sum: number, item: any) => {
      const product = productMap.get(item.productId);
      return sum + ((product ? product.price : 0) * item.quantity);
    }, 0);

    // Check minimum order amount
    // System-wide maximum minimum order amount is $10
    // If shop has a higher minimum, cap it at $10 for customer orders
    const effectiveMinimumOrderAmount = Math.min(shop.minimumOrderAmount || 0, 10);
    
    if (subtotal < effectiveMinimumOrderAmount) {
      throw new AppError(`Minimum order amount is $${effectiveMinimumOrderAmount}`, 400);
    }

    const deliveryFee = shop.deliveryFee || 0;
    const serviceFee = Math.round((subtotal * 0.05) * 100) / 100; // 5% service fee
    const tax = Math.round((subtotal * 0.08) * 100) / 100; // 8% tax
    const total = subtotal + deliveryFee + serviceFee + tax + tip;

    // Generate unique order number
    const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 4).toUpperCase()}`;

    // Create the order with all order items
    const order = await prisma.order.create({
      data: {
        userId: req.user!.id,
        shopId,
        shopName: shop.name,
        orderNumber,
        deliveryAddress,
        deliveryLatitude: deliveryLatitude || 0.0,
        deliveryLongitude: deliveryLongitude || 0.0,
        deliveryInstructions,
        paymentMethod: paymentMethod as PaymentMethod,
        status: OrderStatus.PENDING,
        subtotal,
        deliveryFee,
        serviceFee,
        tax,
        tip,
        discount: 0,
        total,
        items: {
          create: items.map((item: any) => {
            const product = productMap.get(item.productId);
            return {
              productId: item.productId,
               productName: (product as ProductSummary).name,
              quantity: item.quantity,
               productPrice: (product as ProductSummary).price,
               totalPrice: (product as ProductSummary).price * item.quantity,
              instructions: item.instructions || null
            };
          })
        }
      },
      include: {
        shop: {
          select: {
            id: true,
            name: true,
            address: true,
            phone: true
          }
        },
        items: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                price: true,
                imageUrl: true
              }
            }
          }
        }
      }
    });

    // Update product stock quantities
    for (const item of items) {
      const product = productMap.get(item.productId);
      if (product && product.stockQuantity !== null) {
        await prisma.product.update({
          where: { id: item.productId },
          data: {
            stockQuantity: {
              decrement: item.quantity
            }
          }
        });
      }
    }

    // Process payment
    let paymentIntentId: string | null = null;
    let paymentClientSecret: string | undefined = undefined;
    let requiresPaymentAction = false;

    try {
      const whitelabelConfig = getWhitelabelConfig();
      const currency = whitelabelConfig.payment.currency || 'USD';
      
      // Get saved payment method if provided
      const savedPaymentMethodId = req.body.paymentMethodId;
      
      const paymentResult = await paymentService.createPaymentIntent(
        total,
        currency,
        order.id,
        orderNumber,
        paymentMethod as PaymentMethod,
        undefined, // customerId - can be added later for saved customers
        savedPaymentMethodId
      );

      paymentIntentId = paymentResult.paymentIntentId;
      paymentClientSecret = paymentResult.clientSecret;
      requiresPaymentAction = paymentResult.requiresAction || false;

      // Update order with payment ID
      if (paymentIntentId) {
        await prisma.order.update({
          where: { id: order.id },
          data: { paymentId: paymentIntentId },
        });
      }

      // For cash on delivery or already succeeded payments, order is ready
      if (paymentMethod === PaymentMethod.CASH_ON_DELIVERY || paymentResult.status === 'succeeded') {
        // Order status remains PENDING, will be updated when vendor accepts
        logger.info(`Order ${orderNumber} created with payment method: ${paymentMethod}`);
      } else if (requiresPaymentAction) {
        // Payment requires additional action (3D Secure, etc.)
        logger.info(`Order ${orderNumber} created but payment requires action`);
      } else {
        // Payment is processing
        logger.info(`Order ${orderNumber} created with payment processing`);
      }
    } catch (paymentError: any) {
      logger.error('Payment processing error', paymentError);
      // If payment fails, we still create the order but mark it appropriately
      // In production, you might want to delete the order or handle this differently
      if (paymentMethod !== PaymentMethod.CASH_ON_DELIVERY) {
        // For non-COD payments, if payment fails, we should handle it
        // For now, we'll still create the order but the payment will need to be retried
        logger.warn(`Payment processing failed for order ${orderNumber}, but order was created`);
      }
    }

    // Real-time: ETA estimation and notify vendor shop and user
    try {
      // If we have shop coordinates in the response include block, estimate ETA
      if (order.shop && order.deliveryLatitude && order.deliveryLongitude) {
        const estimate = await RoutingService.estimate(
          { lat: order.shop.latitude as any, lng: (order as any).shop.longitude as any },
          { lat: order.deliveryLatitude, lng: order.deliveryLongitude }
        );
        await prisma.order.update({
          where: { id: order.id },
          data: { estimatedDeliveryTime: new Date(Date.now() + estimate.durationSeconds * 1000) },
        });
      }
      const io = getIO();
      if (io) {
        io.to(`shop:${shopId}`).emit('order:new', { orderId: order.id, number: order.orderNumber, total });
        io.to(`user:${req.user!.id}`).emit('order:created', { orderId: order.id, status: OrderStatus.PENDING });
      }
      // Push notification to vendor could be based on vendor owner; here we notify user only
      await NotificationService.sendToUser(req.user!.id, {
        title: 'Order Placed',
        body: `Your order ${order.orderNumber} is pending`,
        data: { orderId: order.id },
      });
    } catch {}

    res.status(201).json({
      status: 'success',
      data: {
        ...order,
        status: OrderStatus.PENDING,
        paymentIntentId: paymentIntentId,
        paymentClientSecret: paymentClientSecret,
        requiresPaymentAction: requiresPaymentAction,
      }
    });
  }

  async getUserOrders(req: AuthenticatedRequest, res: Response) {
    const orders = await prisma.order.findMany({
      where: {
        userId: req.user!.id
      },
      include: {
        shop: {
          select: {
            name: true,
            address: true
          }
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true
              }
            }
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({ status: 'success', data: orders });
  }

  async getOrderById(req: AuthenticatedRequest, res: Response) {
    const user = req.user!;
    
    // Build the where clause based on user role
    let whereClause: any = { id: req.params.id };
    
    if (user.role === 'CUSTOMER') {
      // Customers can only see their own orders
      whereClause.userId = user.id;
    } else if (user.role === 'DELIVERY') {
      // Delivery drivers can see orders assigned to them OR available orders
      whereClause.OR = [
        { deliveryPersonId: user.id },
        { deliveryPersonId: null, status: 'READY_FOR_PICKUP' }
      ];
    } else if (user.role === 'VENDOR') {
      // Vendors can see orders for their shops
      const vendorShops = await prisma.shop.findMany({
        where: { ownerId: user.id },
        select: { id: true }
      });
      const shopIds = vendorShops.map((s: { id: string }) => s.id);
      whereClause.shopId = { in: shopIds };
    } else if (user.role === 'ADMIN') {
      // Admins can see all orders
      // No additional filtering needed
    }

    const order = await prisma.order.findFirst({
      where: whereClause,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true
          }
        },
        shop: {
          select: {
            id: true,
            name: true,
            address: true,
            phone: true,
            latitude: true,
            longitude: true
          }
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true
              }
            }
          }
        },
        deliveryPerson: {
          select: {
            id: true,
            name: true,
            phone: true
          }
        }
      }
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    res.json({ status: 'success', data: order });
  }

  async cancelOrder(req: AuthenticatedRequest, res: Response) {
    const order = await prisma.order.findFirst({
      where: {
        id: req.params.id,
        userId: req.user!.id
      }
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    if (order.status !== OrderStatus.PENDING && order.status !== OrderStatus.ACCEPTED) {
      throw new AppError('Cannot request cancellation for order in current status', 400);
    }

    const updatedOrder = await prisma.order.update({
      where: {
        id: order.id
      },
      data: {
        status: OrderStatus.CANCELLATION_REQUESTED,
        cancellationReason: req.body.reason || 'Cancellation requested by customer'
      }
    });

    // Emit events and push notification
    try {
      const io = getIO();
      if (io) {
        io.to(`order:${updatedOrder.id}`).emit('order:cancellation_requested', { orderId: updatedOrder.id, reason: updatedOrder.cancellationReason });
        io.to(`shop:${updatedOrder.shopId}`).emit('order:cancellation_requested', { orderId: updatedOrder.id });
        io.to(`user:${updatedOrder.userId}`).emit('order:cancellation_requested', { orderId: updatedOrder.id });
      }
      await NotificationService.sendToUser(updatedOrder.userId, {
        title: 'Cancellation requested',
        body: `Your request to cancel order ${order.orderNumber} was submitted`,
        data: { orderId: updatedOrder.id },
      });
    } catch {}

    res.json(updatedOrder);
  }

  async updateTip(req: AuthenticatedRequest, res: Response) {
    const { tip } = req.body;
    
    const order = await prisma.order.findFirst({
      where: {
        id: req.params.id,
        userId: req.user!.id
      }
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    if (order.status !== OrderStatus.DELIVERED) {
      throw new AppError('Can only update tip for delivered orders', 400);
    }

    const updatedOrder = await prisma.order.update({
      where: {
        id: order.id
      },
      data: {
        tip
      }
    });

    // Emit events and push notification
    try {
      const io = getIO();
      if (io) {
        io.to(`order:${updatedOrder.id}`).emit('order:tip_updated', { orderId: updatedOrder.id, tip });
        io.to(`user:${updatedOrder.userId}`).emit('order:tip_updated', { orderId: updatedOrder.id, tip });
        io.to(`shop:${updatedOrder.shopId}`).emit('order:tip_updated', { orderId: updatedOrder.id, tip });
      }
      await NotificationService.sendToUser(updatedOrder.userId, {
        title: 'Tip updated',
        body: `Thank you! Your tip was updated.`,
        data: { orderId: updatedOrder.id },
      });
    } catch {}

    res.json(updatedOrder);
  }

  async confirmPayment(req: AuthenticatedRequest, res: Response) {
    const { orderId, paymentMethodId } = req.body;

    if (!orderId) {
      throw new AppError('Order ID is required', 400);
    }

    // Get order
    const order = await prisma.order.findFirst({
      where: {
        id: orderId,
        userId: req.user!.id,
      },
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    if (!order.paymentId) {
      throw new AppError('Order does not have a payment intent', 400);
    }

    if (order.paymentMethod === PaymentMethod.CASH_ON_DELIVERY) {
      throw new AppError('Cash on delivery orders do not require payment confirmation', 400);
    }

    try {
      // Confirm the payment intent
      const paymentResult = await paymentService.confirmPaymentIntent(
        order.paymentId,
        paymentMethodId
      );

      if (paymentResult.success) {
        // Payment succeeded - order status remains PENDING until vendor accepts
        // The webhook will also handle this, but we update here for immediate response
        logger.info(`Payment confirmed for order ${order.orderNumber}`);

        // Emit real-time update
        const io = getIO();
        if (io) {
          io.to(`order:${order.id}`).emit('order:payment_confirmed', { orderId: order.id });
          io.to(`user:${order.userId}`).emit('order:payment_confirmed', { orderId: order.id });
        }

        res.json({
          status: 'success',
          message: 'Payment confirmed successfully',
          data: {
            orderId: order.id,
            paymentStatus: paymentResult.status,
          },
        });
      } else {
        // Payment requires additional action
        res.status(202).json({
          status: 'requires_action',
          message: paymentResult.message,
          data: {
            orderId: order.id,
            paymentStatus: paymentResult.status,
          },
        });
      }
    } catch (error: any) {
      logger.error('Payment confirmation failed', error);
      throw new AppError(
        error.message || 'Failed to confirm payment',
        error.statusCode || 500
      );
    }
  }

  async processRefund(req: AuthenticatedRequest, res: Response) {
    const { orderId, amount, reason } = req.body;

    if (!orderId) {
      throw new AppError('Order ID is required', 400);
    }

    // Get order
    const order = await prisma.order.findFirst({
      where: {
        id: orderId,
        userId: req.user!.id,
      },
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    // Only allow refunds for delivered or cancelled orders
    if (order.status !== OrderStatus.DELIVERED && order.status !== OrderStatus.CANCELLED) {
      throw new AppError('Refunds can only be processed for delivered or cancelled orders', 400);
    }

    if (!order.paymentId) {
      throw new AppError('Order does not have a payment ID', 400);
    }

    // Default to full refund if amount not specified
    const refundAmount = amount || order.total;

    if (refundAmount > order.total) {
      throw new AppError('Refund amount cannot exceed order total', 400);
    }

    try {
      // Process refund through payment service
      const refundResult = await paymentService.processRefund(
        order.paymentId,
        refundAmount,
        reason
      );

      if (refundResult.success) {
        // Update order status to REFUNDED
        const updatedOrder = await prisma.order.update({
          where: { id: order.id },
          data: { status: OrderStatus.REFUNDED },
        });

        // Emit real-time update
        const io = getIO();
        if (io) {
          io.to(`order:${order.id}`).emit('order:refunded', {
            orderId: order.id,
            refundId: refundResult.refundId,
            amount: refundResult.amount,
          });
          io.to(`user:${order.userId}`).emit('order:refunded', {
            orderId: order.id,
            refundId: refundResult.refundId,
          });
          io.to(`shop:${order.shopId}`).emit('order:refunded', {
            orderId: order.id,
          });
        }

        // Send notification
        await NotificationService.sendToUser(order.userId, {
          title: 'Refund Processed',
          body: `Refund of $${refundResult.amount.toFixed(2)} has been processed for order ${order.orderNumber}`,
          data: { orderId: order.id, refundId: refundResult.refundId },
        });

        res.json({
          status: 'success',
          message: refundResult.message || 'Refund processed successfully',
          data: {
            orderId: order.id,
            refundId: refundResult.refundId,
            refundAmount: refundResult.amount,
            orderStatus: updatedOrder.status,
          },
        });
      } else {
        throw new AppError('Failed to process refund', 500);
      }
    } catch (error: any) {
      logger.error('Refund processing failed', error);
      throw new AppError(
        error.message || 'Failed to process refund',
        error.statusCode || 500
      );
    }
  }

  async trackOrder(req: AuthenticatedRequest, res: Response) {
    const order = await prisma.order.findFirst({
      where: {
        id: req.params.id,
        userId: req.user!.id
      },
      include: {
        shop: {
          select: {
            name: true,
            address: true
          }
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true
              }
            }
          }
        }
      }
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    res.json({
      status: order.status,
      estimatedDeliveryTime: order.estimatedDeliveryTime,
    });
  }
} 
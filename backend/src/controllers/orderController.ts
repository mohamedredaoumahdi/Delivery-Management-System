import { Response } from 'express';
import { OrderStatus, PaymentMethod } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';
import { getIO } from '@/services/socketService';
import { NotificationService } from '@/services/notificationService';
import { RoutingService } from '@/services/routingService';

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
        isOpen: true
      } 
    });
    
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    if (!shop.isActive || !shop.isOpen) {
      throw new AppError('Shop is currently not accepting orders', 400);
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
    if (subtotal < shop.minimumOrderAmount) {
      throw new AppError(`Minimum order amount is $${shop.minimumOrderAmount}`, 400);
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

    // Payment processing placeholder:
    // - CASH_ON_DELIVERY: leave as PENDING
    // - CARD/WALLET/BANK: integrate with Stripe PaymentIntents in M2

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
        status: OrderStatus.PENDING
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
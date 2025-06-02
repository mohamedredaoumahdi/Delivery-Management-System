import { Response } from 'express';
import { PrismaClient, OrderStatus, PaymentMethod } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';

const prisma = new PrismaClient();

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

    // Create a map of product prices for easy lookup
    const productMap = new Map(products.map(p => [p.id, p]));

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
      return sum + (product!.price * item.quantity);
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
              productName: product!.name,
              quantity: item.quantity,
              productPrice: product!.price,
              totalPrice: product!.price * item.quantity,
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

    // TODO: Process payment here based on payment method
    // For now, we'll mark cash orders as confirmed and card orders as pending payment
    let updatedStatus = OrderStatus.PENDING;
    
    switch (paymentMethod) {
      case PaymentMethod.CASH_ON_DELIVERY:
        // Cash orders are accepted immediately
        updatedStatus = OrderStatus.ACCEPTED;
        break;
      case PaymentMethod.CARD:
      case PaymentMethod.WALLET:
      case PaymentMethod.BANK_TRANSFER:
        // These would require payment processing
        // For now, we'll simulate successful payment
        updatedStatus = OrderStatus.ACCEPTED;
        break;
    }

    // Update order status if needed
    if (updatedStatus !== OrderStatus.PENDING) {
      await prisma.order.update({
        where: { id: order.id },
        data: { status: updatedStatus }
      });
    }

    // TODO: Send notification to vendor about new order
    // TODO: Send confirmation email/SMS to customer

    res.status(201).json({
      status: 'success',
      data: {
        ...order,
        status: updatedStatus
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

    res.json(order);
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
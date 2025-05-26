import { Response } from 'express';
import { PrismaClient, OrderStatus, PaymentMethod } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';

const prisma = new PrismaClient();

export class OrderController {
  async createOrder(req: AuthenticatedRequest, res: Response) {
    const { items, shopId, deliveryAddress, paymentMethod } = req.body;

    // Fetch shop name
    const shop = await prisma.shop.findUnique({ where: { id: shopId }, select: { name: true } });
    if (!shop) throw new AppError('Shop not found', 404);

    // Fetch products to get their prices
    const productIds = items.map((item: any) => item.productId);
    const products = await prisma.product.findMany({
      where: {
        id: { in: productIds }
      },
      select: {
        id: true,
        price: true,
        name: true,
        inStock: true,
        stockQuantity: true
      }
    });

    // Create a map of product prices
    const productMap = new Map(products.map(p => [p.id, p]));

    // Validate all products exist and are in stock
    for (const item of items) {
      const product = productMap.get(item.productId);
      if (!product) {
        throw new AppError(`Product with ID ${item.productId} not found`, 404);
      }
      if (!product.inStock || (product.stockQuantity !== null && product.stockQuantity < item.quantity)) {
        throw new AppError(`Product ${product.name} is out of stock or has insufficient quantity`, 400);
      }
    }

    const order = await prisma.order.create({
      data: {
        userId: req.user!.id,
        shopId,
        shopName: shop.name,
        orderNumber: `ORD-${Date.now()}`,
        deliveryAddress,
        deliveryLatitude: 0.0,
        deliveryLongitude: 0.0,
        paymentMethod: PaymentMethod.CASH_ON_DELIVERY,
        status: OrderStatus.PENDING,
        subtotal: items.reduce((sum: number, item: any) => {
          const product = productMap.get(item.productId);
          return sum + (product!.price * item.quantity);
        }, 0),
        deliveryFee: req.body.deliveryFee || 0,
        serviceFee: req.body.serviceFee || 0,
        tax: req.body.tax || 0,
        total: items.reduce((sum: number, item: any) => {
          const product = productMap.get(item.productId);
          return sum + (product!.price * item.quantity);
        }, 0) + (req.body.deliveryFee || 0) + (req.body.serviceFee || 0) + (req.body.tax || 0),
        items: {
          create: items.map((item: any) => {
            const product = productMap.get(item.productId);
            return {
              productId: item.productId,
              productName: product!.name,
              quantity: item.quantity,
              productPrice: product!.price,
              totalPrice: product!.price * item.quantity
            };
          })
        }
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

    res.status(201).json(order);
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

    res.json(orders);
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
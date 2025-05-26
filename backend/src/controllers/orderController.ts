import { Response } from 'express';
import { PrismaClient, OrderStatus } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';

const prisma = new PrismaClient();

export class OrderController {
  async createOrder(req: AuthenticatedRequest, res: Response) {
    const { items, shopId, deliveryAddress, paymentMethod } = req.body;

    const order = await prisma.order.create({
      data: {
        userId: req.user!.id,
        shopId,
        shopName: req.body.shopName,
        orderNumber: `ORD-${Date.now()}`,
        deliveryAddress,
        deliveryLatitude: req.body.deliveryLatitude,
        deliveryLongitude: req.body.deliveryLongitude,
        paymentMethod,
        status: OrderStatus.PENDING,
        subtotal: items.reduce((sum: number, item: any) => sum + (item.price * item.quantity), 0),
        deliveryFee: req.body.deliveryFee || 0,
        serviceFee: req.body.serviceFee || 0,
        tax: req.body.tax || 0,
        total: items.reduce((sum: number, item: any) => sum + (item.price * item.quantity), 0) + 
               (req.body.deliveryFee || 0) + 
               (req.body.serviceFee || 0) + 
               (req.body.tax || 0),
        items: {
          create: items.map((item: any) => ({
            productId: item.productId,
            quantity: item.quantity,
            price: item.price
          }))
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

    if (order.status !== OrderStatus.PENDING) {
      throw new AppError('Cannot cancel order in current status', 400);
    }

    const updatedOrder = await prisma.order.update({
      where: {
        id: order.id
      },
      data: {
        status: OrderStatus.CANCELLED
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
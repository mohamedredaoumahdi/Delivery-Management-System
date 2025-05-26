import { Response } from 'express';
import { PrismaClient, OrderStatus } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';

const prisma = new PrismaClient();

export class DeliveryController {
  async getAssignedOrders(req: AuthenticatedRequest, res: Response) {
    const orders = await prisma.order.findMany({
      where: {
        status: {
          in: [OrderStatus.ACCEPTED, OrderStatus.READY_FOR_PICKUP, OrderStatus.IN_DELIVERY]
        }
      },
      include: {
        shop: {
          select: {
            name: true,
            address: true,
          }
        },
        user: {
          select: {
            name: true,
            phone: true,
            addresses: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json(orders);
  }

  async getAvailableOrders(req: AuthenticatedRequest, res: Response) {
    const orders = await prisma.order.findMany({
      where: {
        status: OrderStatus.READY_FOR_PICKUP,
      },
      include: {
        shop: {
          select: {
            name: true,
            address: true,
          }
        },
        user: {
          select: {
            name: true,
            phone: true,
            addresses: true
          }
        }
      },
      orderBy: {
        createdAt: 'asc'
      }
    });

    res.json(orders);
  }

  async acceptOrder(req: AuthenticatedRequest, res: Response) {
    const { id } = req.params;

    const order = await prisma.order.update({
      where: {
        id,
        status: OrderStatus.READY_FOR_PICKUP,
      },
      data: {
        status: OrderStatus.ACCEPTED
      },
      include: {
        shop: {
          select: {
            name: true,
            address: true,
          }
        },
        user: {
          select: {
            name: true,
            phone: true,
            addresses: true
          }
        }
      }
    });

    if (!order) {
      throw new AppError('Order not available for delivery', 400);
    }

    res.json(order);
  }

  async updateOrderStatus(req: AuthenticatedRequest, res: Response) {
    const { id } = req.params;
    const { status } = req.body;

    const order = await prisma.order.update({
      where: {
        id,
      },
      data: {
        status: status as OrderStatus
      }
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    res.json(order);
  }

  async updateLocation(req: AuthenticatedRequest, res: Response) {
    const { latitude, longitude } = req.body;

    res.json({ message: 'Location update not supported' });
  }

  async getDeliveryHistory(req: AuthenticatedRequest, res: Response) {
    const orders = await prisma.order.findMany({
      where: {
        status: OrderStatus.DELIVERED
      },
      include: {
        shop: {
          select: {
            name: true,
            address: true,
          }
        },
        user: {
          select: {
            name: true,
            addresses: true
          }
        }
      },
      orderBy: {
        deliveredAt: 'desc'
      }
    });

    res.json(orders);
  }
} 
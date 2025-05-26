import { Request, Response, NextFunction } from 'express';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { AuthenticatedRequest } from '@/types/express';

export class DeliveryController {
  getAssignedOrders = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const orders = await prisma.order.findMany({
      where: {
        deliveryPersonId: req.user!.id,
      },
      include: {
        items: true,
        shop: true,
        user: true,
      },
    });

    res.json({
      status: 'success',
      data: orders,
    });
  });

  getAvailableOrders = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const orders = await prisma.order.findMany({
      where: {
        status: 'READY_FOR_PICKUP',
        deliveryPersonId: null,
      },
      include: {
        items: true,
        shop: true,
        user: true,
      },
    });

    res.json({
      status: 'success',
      data: orders,
    });
  });

  acceptOrder = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const order = await prisma.order.update({
      where: { id: req.params.id },
      data: {
        deliveryPersonId: req.user!.id,
        status: 'IN_DELIVERY',
      },
    });

    res.json({
      status: 'success',
      data: order,
    });
  });

  markPickedUp = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const order = await prisma.order.update({
      where: { id: req.params.id },
      data: {
        status: 'IN_DELIVERY',
      },
    });

    res.json({
      status: 'success',
      data: order,
    });
  });

  markDelivered = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const order = await prisma.order.update({
      where: { id: req.params.id },
      data: {
        status: 'DELIVERED',
        deliveredAt: new Date(),
      },
    });

    res.json({
      status: 'success',
      data: order,
    });
  });

  updateLocation = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { latitude, longitude } = req.body;

    // Create a new location record
    await prisma.deliveryLocation.create({
      data: {
        userId: req.user!.id,
        latitude,
        longitude,
      },
    });

    res.json({
      status: 'success',
      message: 'Location updated successfully',
    });
  });

  getDeliveryStats = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const stats = await prisma.order.groupBy({
      by: ['status'],
      where: {
        deliveryPersonId: req.user!.id,
      },
      _count: true,
    });

    res.json({
      status: 'success',
      data: stats,
    });
  });

  getEarnings = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const earnings = await prisma.order.aggregate({
      where: {
        deliveryPersonId: req.user!.id,
        status: 'DELIVERED',
      },
      _sum: {
        deliveryFee: true,
      },
    });

    res.json({
      status: 'success',
      data: {
        totalEarnings: earnings._sum?.deliveryFee || 0,
      },
    });
  });
} 
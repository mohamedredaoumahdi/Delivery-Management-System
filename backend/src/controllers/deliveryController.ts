import { Request, Response, NextFunction } from 'express';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { AuthenticatedRequest } from '@/types/express';
import { getIO } from '@/services/socketService';
import { NotificationService } from '@/services/notificationService';
import { RoutingService } from '@/services/routingService';

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

    // Notify user and shop
    try {
      const io = getIO();
      if (io) {
        io.to(`order:${order.id}`).emit('order:status', { orderId: order.id, status: order.status });
        io.to(`user:${order.userId}`).emit('order:status', { orderId: order.id, status: order.status });
        io.to(`shop:${order.shopId}`).emit('order:status', { orderId: order.id, status: order.status });
      }
      await NotificationService.sendToUser(order.userId, {
        title: 'Order Update',
        body: `Your order status is now ${order.status}`,
        data: { orderId: order.id },
      });
    } catch {}

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

    try {
      const io = getIO();
      if (io) {
        io.to(`order:${order.id}`).emit('order:status', { orderId: order.id, status: order.status });
        io.to(`user:${order.userId}`).emit('order:status', { orderId: order.id, status: order.status });
        io.to(`shop:${order.shopId}`).emit('order:status', { orderId: order.id, status: order.status });
      }
      await NotificationService.sendToUser(order.userId, {
        title: 'Order Update',
        body: `Your order status is now ${order.status}`,
        data: { orderId: order.id },
      });
    } catch {}

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

    try {
      const io = getIO();
      if (io) {
        io.to(`order:${order.id}`).emit('order:status', { orderId: order.id, status: order.status });
        io.to(`user:${order.userId}`).emit('order:status', { orderId: order.id, status: order.status });
        io.to(`shop:${order.shopId}`).emit('order:status', { orderId: order.id, status: order.status });
      }
      await NotificationService.sendToUser(order.userId, {
        title: 'Order Delivered',
        body: `Your order has been delivered`,
        data: { orderId: order.id },
      });
    } catch {}

    res.json({
      status: 'success',
      data: order,
    });
  });

  updateLocation = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { latitude, longitude } = req.body;

    // Rate throttling: allow at most 1 location write per 3 seconds per driver
    // Simple implementation leveraging updatedAt gap
    const last = await prisma.deliveryLocation.findFirst({
      where: { userId: req.user!.id },
      orderBy: { timestamp: 'desc' },
    });
    const now = Date.now();
    const throttled = last && now - new Date(last.timestamp).getTime() < 3000;
    if (throttled) {
      // Skip DB write, still broadcast
      try {
        const io = getIO();
        if (io) {
          io.to(`user:${req.user!.id}`).emit('driver:location', { latitude, longitude, at: new Date().toISOString() });
        }
      } catch {}
      // Proceed to compute ETA updates even if throttled
    }

    // Persist at throttled cadence
    const location = throttled
      ? null
      : await prisma.deliveryLocation.create({
          data: {
            userId: req.user!.id,
            latitude,
            longitude,
          },
        });

    try {
      const io = getIO();
      if (io) {
        io.to(`user:${req.user!.id}`).emit('driver:location', { latitude, longitude, at: new Date().toISOString() });
      }
    } catch {}

    // Live ETA updates for driver's active orders
    try {
      const activeOrders = await prisma.order.findMany({
        where: {
          deliveryPersonId: req.user!.id,
          status: { in: ['READY_FOR_PICKUP', 'IN_DELIVERY'] },
        },
        select: {
          id: true,
          shopId: true,
          userId: true,
          status: true,
          deliveryLatitude: true,
          deliveryLongitude: true,
          shop: { select: { latitude: true, longitude: true } },
        },
        take: 5,
      });

      const io = getIO();
      for (const o of activeOrders) {
        const target = o.status === 'READY_FOR_PICKUP'
          ? { lat: o.shop?.latitude ?? 0, lng: o.shop?.longitude ?? 0 }
          : { lat: o.deliveryLatitude ?? 0, lng: o.deliveryLongitude ?? 0 };

        const estimate = await RoutingService.estimate(
          { lat: latitude, lng: longitude },
          target
        );

        // Update order ETA timestamp
        await prisma.order.update({
          where: { id: o.id },
          data: { estimatedDeliveryTime: new Date(Date.now() + estimate.durationSeconds * 1000) },
        });

        if (io) {
          io.to(`order:${o.id}`).emit('order:eta', {
            orderId: o.id,
            etaSeconds: estimate.durationSeconds,
            distanceMeters: estimate.distanceMeters,
            provider: estimate.provider,
          });
          io.to(`user:${o.userId}`).emit('order:eta', {
            orderId: o.id,
            etaSeconds: estimate.durationSeconds,
            distanceMeters: estimate.distanceMeters,
            provider: estimate.provider,
          });
          io.to(`shop:${o.shopId}`).emit('order:eta', {
            orderId: o.id,
            etaSeconds: estimate.durationSeconds,
            distanceMeters: estimate.distanceMeters,
            provider: estimate.provider,
          });
        }
      }
    } catch {}

    res.json({
      status: 'success',
      message: 'Location updated successfully',
      data: location,
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
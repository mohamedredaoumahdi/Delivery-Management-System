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
    const { period = 'today' } = req.query;
    const driverId = req.user!.id;

    // Calculate date range based on period
    const now = new Date();
    let startDate: Date;
    
    switch (period) {
      case 'today':
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        break;
      case 'week':
        startDate = new Date(now);
        startDate.setDate(now.getDate() - 7);
        break;
      case 'month':
        startDate = new Date(now);
        startDate.setMonth(now.getMonth() - 1);
        break;
      case '3months':
        startDate = new Date(now);
        startDate.setMonth(now.getMonth() - 3);
        break;
      default:
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    }

    // Get all delivered orders for this driver
    const deliveredOrders = await prisma.order.findMany({
      where: {
        deliveryPersonId: driverId,
        status: 'DELIVERED',
        deliveredAt: {
          gte: startDate,
        },
      },
      include: {
        user: {
          select: {
            name: true,
          },
        },
      },
      orderBy: {
        deliveredAt: 'desc',
      },
    });

    // Type alias for order with user
    type OrderWithUser = typeof deliveredOrders[0];

    // Calculate earnings
    const totalEarnings = deliveredOrders.reduce((sum: number, order: OrderWithUser) => {
      const deliveryFee = order.deliveryFee || 0;
      const tip = order.tip || 0;
      // Base delivery fee + tip + 2% of order total as commission
      const commission = (order.total || 0) * 0.02;
      return sum + deliveryFee + tip + commission;
    }, 0);

    // Today's earnings
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayOrders = deliveredOrders.filter(
      (order: OrderWithUser) => order.deliveredAt && order.deliveredAt >= todayStart
    );
    const todayEarnings = todayOrders.reduce((sum: number, order: OrderWithUser) => {
      const deliveryFee = order.deliveryFee || 0;
      const tip = order.tip || 0;
      const commission = (order.total || 0) * 0.02;
      return sum + deliveryFee + tip + commission;
    }, 0);

    // Calculate breakdown
    const basePay = deliveredOrders.reduce((sum: number, order: OrderWithUser) => sum + (order.deliveryFee || 0), 0);
    const tips = deliveredOrders.reduce((sum: number, order: OrderWithUser) => sum + (order.tip || 0), 0);
    const bonuses = 0; // Can be calculated based on performance metrics
    const distanceBonus = deliveredOrders.reduce((sum: number, order: OrderWithUser) => {
      // Assume $0.50 per km as distance bonus
      return sum + (2.0 * 0.5); // Using default distance of 2km
    }, 0);

    // Recent deliveries (last 10)
    const recentDeliveries = deliveredOrders.slice(0, 10).map((order: OrderWithUser) => ({
      orderNumber: order.orderNumber || `ORD-${order.id.substring(0, 8)}`,
      completedAt: order.deliveredAt?.toISOString() || order.updatedAt.toISOString(),
      earnings: (order.deliveryFee || 0) + (order.tip || 0) + ((order.total || 0) * 0.02),
      distance: 2.0, // TODO: Calculate actual distance
    }));

    // Payment history
    const paymentHistory: Array<{ date: string; amount: number; description: string; status: string }> = [];
    
    if (period === 'today') {
      // For today, show individual delivery payments
      const todayOrders = deliveredOrders.filter(
        (order: OrderWithUser) => order.deliveredAt && order.deliveredAt >= todayStart
      );
      
      todayOrders.forEach((order: OrderWithUser) => {
        const earnings = (order.deliveryFee || 0) + (order.tip || 0) + ((order.total || 0) * 0.02);
        if (earnings > 0) {
          paymentHistory.push({
            date: order.deliveredAt?.toISOString() || order.updatedAt.toISOString(),
            amount: earnings,
            description: `Order ${order.orderNumber || `ORD-${order.id.substring(0, 8)}`}`,
            status: 'PAID',
          });
        }
      });
    } else {
      // For longer periods, show weekly summaries
      const daysDiff = Math.floor((now.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000));
      const weeksToShow = Math.min(Math.ceil(daysDiff / 7), 8); // Show up to 8 weeks
      
      for (let i = 0; i < weeksToShow; i++) {
        const weekStart = new Date(now);
        weekStart.setDate(now.getDate() - ((i + 1) * 7));
        weekStart.setHours(0, 0, 0, 0);
        
        const weekEnd = new Date(weekStart);
        weekEnd.setDate(weekStart.getDate() + 7);
        weekEnd.setHours(23, 59, 59, 999);
        
        const weekOrders = deliveredOrders.filter(
          (order: OrderWithUser) => {
            if (!order.deliveredAt) return false;
            const deliveredDate = new Date(order.deliveredAt);
            return deliveredDate >= weekStart && deliveredDate < weekEnd;
          }
        );
        
        const weekEarnings = weekOrders.reduce((sum: number, order: OrderWithUser) => {
          const deliveryFee = order.deliveryFee || 0;
          const tip = order.tip || 0;
          const commission = (order.total || 0) * 0.02;
          return sum + deliveryFee + tip + commission;
        }, 0);

        if (weekEarnings > 0) {
          paymentHistory.push({
            date: weekStart.toISOString(),
            amount: weekEarnings,
            description: `Week of ${weekStart.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`,
            status: 'PAID',
          });
        }
      }
      
      // Sort by date descending (most recent first)
      paymentHistory.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    }

    // Calculate online time (simplified - can be enhanced with actual tracking)
    const onlineMinutes = deliveredOrders.length * 30; // Assume 30 minutes per delivery
    const onlineHours = Math.floor(onlineMinutes / 60);

    res.json({
      status: 'success',
      data: {
        totalEarnings,
        todayEarnings,
        deliveryCount: deliveredOrders.length,
        averagePerOrder: deliveredOrders.length > 0 ? totalEarnings / deliveredOrders.length : 0,
        onlineHours,
        onlineMinutes: onlineMinutes % 60,
        recentDeliveries,
        basePay,
        tips,
        bonuses,
        distanceBonus,
        paymentHistory,
        // Additional fields for UI
        weeklyDeliveries: deliveredOrders.filter(
          (order: OrderWithUser) => order.deliveredAt && 
          order.deliveredAt >= new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
        ).length,
        weeklyEarnings: deliveredOrders
          .filter((order: OrderWithUser) => order.deliveredAt && 
            order.deliveredAt >= new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000))
          .reduce((sum: number, order: OrderWithUser) => {
            const deliveryFee = order.deliveryFee || 0;
            const tip = order.tip || 0;
            const commission = (order.total || 0) * 0.02;
            return sum + deliveryFee + tip + commission;
          }, 0),
        weeklyHours: Math.floor(onlineMinutes / 60),
        acceptanceRate: 95, // TODO: Calculate from actual data
        customerRating: 4.8, // TODO: Get from reviews
        onTimeRate: 98, // TODO: Calculate from actual data
        averageTip: tips / deliveredOrders.length || 0,
        bestTip: deliveredOrders.length > 0 ? Math.max(...deliveredOrders.map((o: OrderWithUser) => o.tip || 0)) : 0,
        tipRate: deliveredOrders.length > 0 ? (deliveredOrders.filter((o: OrderWithUser) => (o.tip || 0) > 0).length / deliveredOrders.length) * 100 : 0,
        dailyGoal: 100, // Can be configurable
        weeklyGoal: 500, // Can be configurable
      },
    });
  });
} 
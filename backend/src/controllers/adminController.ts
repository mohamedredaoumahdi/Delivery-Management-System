import { Request, Response, NextFunction } from 'express';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { AuthenticatedRequest } from '@/types/express';
import { config } from '@/config/config';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import sharp from 'sharp';
import fs from 'fs/promises';
import bcrypt from 'bcrypt';
import { OrderStatus, UserRole, Order, OrderItem, Review } from '@prisma/client';

const ACTIVE_ORDER_STATUSES: OrderStatus[] = [
  OrderStatus.PENDING,
  OrderStatus.ACCEPTED,
  OrderStatus.PREPARING,
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.IN_DELIVERY,
];

const PENDING_DELIVERY_STATUSES: OrderStatus[] = [
  OrderStatus.READY_FOR_PICKUP,
  OrderStatus.IN_DELIVERY,
];

const EXCLUDED_REVENUE_STATUSES: OrderStatus[] = [
  OrderStatus.CANCELLED,
  OrderStatus.REFUNDED,
];

export class AdminController {
  // User management
  createUser = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { email, password, name, role, phone, isActive = true, isEmailVerified = false, isPhoneVerified = false } = req.body;

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return next(new AppError('User with this email already exists', 400));
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        name,
        role,
        phone,
        isActive,
        isEmailVerified,
        isPhoneVerified,
      },
    });

    res.status(201).json({ status: 'success', data: user });
  });

  getUsers = catchAsync(async (req: Request, res: Response) => {
    const users = await prisma.user.findMany();
    res.json({ status: 'success', data: users });
  });

  getUserById = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const user = await prisma.user.findUnique({ where: { id: req.params.id } });
    if (!user) return next(new AppError('User not found', 404));
    res.json({ status: 'success', data: user });
  });

  updateUser = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const user = await prisma.user.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json({ status: 'success', data: user });
  });

  deleteUser = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    await prisma.user.delete({ where: { id: req.params.id } });
    res.json({ status: 'success', data: null });
  });

  getDashboardOverview = catchAsync(async (req: Request, res: Response) => {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(startOfToday);
    const dayOfWeek = startOfWeek.getDay();
    const diffToMonday = (dayOfWeek + 6) % 7;
    startOfWeek.setDate(startOfWeek.getDate() - diffToMonday);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const last30Days = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 30);
    const onlineThreshold = new Date(now.getTime() - 5 * 60 * 1000);
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);

    const [
      ordersToday,
      ordersWeek,
      ordersMonth,
      activeOrders,
      pendingDeliveries,
      revenueTodayAgg,
      revenueWeekAgg,
      revenueMonthAgg,
      revenueTotalAgg,
      totalVendors,
      activeVendors,
      vendorRatingAgg,
      topVendorsRaw,
      totalDeliveryAgents,
      activeDeliveryAgents,
      deliveryOnlineGroups,
      deliveredToday,
      recentDeliveredOrders,
      totalCustomers,
      recentCustomers,
    ] = await Promise.all([
      prisma.order.count({ where: { createdAt: { gte: startOfToday } } }),
      prisma.order.count({ where: { createdAt: { gte: startOfWeek } } }),
      prisma.order.count({ where: { createdAt: { gte: startOfMonth } } }),
      prisma.order.count({ where: { status: { in: ACTIVE_ORDER_STATUSES } } }),
      prisma.order.count({ where: { status: { in: PENDING_DELIVERY_STATUSES } } }),
      prisma.order.aggregate({
        _sum: { total: true },
        where: {
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
          createdAt: { gte: startOfToday },
        },
      }),
      prisma.order.aggregate({
        _sum: { total: true },
        where: {
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
          createdAt: { gte: startOfWeek },
        },
      }),
      prisma.order.aggregate({
        _sum: { total: true },
        where: {
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
          createdAt: { gte: startOfMonth },
        },
      }),
      prisma.order.aggregate({
        _sum: { total: true },
        where: {
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
      }),
      prisma.user.count({ where: { role: UserRole.VENDOR } }),
      prisma.user.count({ where: { role: UserRole.VENDOR, isActive: true } }),
      prisma.shop.aggregate({
        _avg: { rating: true },
      }),
      prisma.order.groupBy({
        by: ['shopId', 'shopName'],
        where: {
          createdAt: { gte: last30Days },
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
        _count: { _all: true },
        _sum: { total: true },
        orderBy: {
          _sum: { total: 'desc' },
        },
        take: 5,
      }),
      prisma.user.count({ where: { role: UserRole.DELIVERY } }),
      prisma.user.count({ where: { role: UserRole.DELIVERY, isActive: true } }),
      prisma.deliveryLocation.groupBy({
        by: ['userId'],
        where: {
          timestamp: { gte: onlineThreshold },
        },
      }),
      prisma.order.count({
        where: {
          status: OrderStatus.DELIVERED,
          deliveredAt: { gte: startOfToday },
        },
      }),
      prisma.order.findMany({
        where: {
          status: OrderStatus.DELIVERED,
          deliveredAt: { not: null },
        },
        select: {
          createdAt: true,
          deliveredAt: true,
        },
        orderBy: { deliveredAt: 'desc' },
        take: 100,
      }),
      prisma.user.count({ where: { role: UserRole.CUSTOMER } }),
      prisma.user.findMany({
        where: {
          role: UserRole.CUSTOMER,
          createdAt: { gte: sixMonthsAgo },
        },
        select: { createdAt: true },
      }),
    ]);

    const averageDeliveryTimeMinutes =
      recentDeliveredOrders.length === 0
        ? 0
        : Math.round(
            recentDeliveredOrders.reduce(
              (accumulator: number, order: { createdAt: Date; deliveredAt: Date | null }) => {
                const diffMs = order.deliveredAt!.getTime() - order.createdAt.getTime();
                return accumulator + diffMs / 60000;
              },
              0,
            ) / recentDeliveredOrders.length,
          );

    const onlineAgents = deliveryOnlineGroups.length;
    const offlineAgents = Math.max(activeDeliveryAgents - onlineAgents, 0);

    const vendorPerformance = topVendorsRaw.map((vendor: {
      shopId: string;
      shopName: string;
      _count: { _all: number };
      _sum: { total: number | null };
    }) => ({
      shopId: vendor.shopId,
      shopName: vendor.shopName,
      orders: vendor._count._all,
      revenue: vendor._sum.total ?? 0,
    }));

    const monthBuckets = Array.from({ length: 6 }, (_, index) => {
      const date = new Date(now.getFullYear(), now.getMonth() - (5 - index), 1);
      const key = `${date.getFullYear()}-${date.getMonth()}`;
      const label = date.toLocaleString('default', { month: 'short' });
      return { key, label };
    });

    const customerCountsByKey = recentCustomers.reduce(
      (accumulator: Record<string, number>, customer: { createdAt: Date }) => {
        const key = `${customer.createdAt.getFullYear()}-${customer.createdAt.getMonth()}`;
        accumulator[key] = (accumulator[key] ?? 0) + 1;
        return accumulator;
      },
      {} as Record<string, number>,
    );

    const customerTrend = monthBuckets.map((bucket) => ({
      label: bucket.label,
      count: customerCountsByKey[bucket.key] ?? 0,
    }));

    const lastMonthCount = customerTrend[customerTrend.length - 1]?.count ?? 0;
    const previousMonthCount = customerTrend[customerTrend.length - 2]?.count ?? 0;
    const rawGrowthRate =
      previousMonthCount === 0
        ? lastMonthCount > 0
          ? 100
          : 0
        : ((lastMonthCount - previousMonthCount) / previousMonthCount) * 100;

    res.json({
      status: 'success',
      data: {
        orders: {
          totals: {
            today: ordersToday,
            week: ordersWeek,
            month: ordersMonth,
          },
          active: activeOrders,
          pendingDeliveries,
        },
        revenue: {
          today: revenueTodayAgg._sum.total ?? 0,
          week: revenueWeekAgg._sum.total ?? 0,
          month: revenueMonthAgg._sum.total ?? 0,
          total: revenueTotalAgg._sum.total ?? 0,
        },
        vendors: {
          total: totalVendors,
          active: activeVendors,
          averageRating: vendorRatingAgg._avg.rating
            ? Number(vendorRatingAgg._avg.rating.toFixed(2))
            : 0,
          topPerformers: vendorPerformance,
        },
        delivery: {
          totalAgents: totalDeliveryAgents,
          activeAgents: activeDeliveryAgents,
          onlineAgents,
          offlineAgents,
          completedToday: deliveredToday,
          averageDeliveryTimeMinutes,
        },
        customers: {
          totalCustomers,
          growthRate: Number(rawGrowthRate.toFixed(1)),
          trend: customerTrend,
        },
        generatedAt: now.toISOString(),
      },
    });
  });

  // Shop management
  getShops = catchAsync(async (req: Request, res: Response) => {
    const shops = await prisma.shop.findMany();
    res.json({ status: 'success', data: shops });
  });

  createShop = catchAsync(async (req: Request, res: Response) => {
    const { categoryId, ...rest } = req.body;
    const shop = await prisma.shop.create({
      data: {
        ...rest,
        category: rest.category as any,
      },
    });
    res.status(201).json({ status: 'success', data: shop });
  });

  getShopById = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const shop = await prisma.shop.findUnique({ where: { id: req.params.id } });
    if (!shop) return next(new AppError('Shop not found', 404));
    res.json({ status: 'success', data: shop });
  });

  updateShop = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const shop = await prisma.shop.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json({ status: 'success', data: shop });
  });

  deleteShop = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    await prisma.shop.delete({ where: { id: req.params.id } });
    res.json({ status: 'success', data: null });
  });

  // Vendor approval management
  approveVendor = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const { reason } = req.body;

    const shop = await prisma.shop.findUnique({
      where: { id },
      include: { owner: { select: { id: true, name: true, email: true } } },
    });

    if (!shop) {
      return next(new AppError('Vendor not found', 404));
    }

    const updatedShop = await prisma.shop.update({
      where: { id },
      data: {
        isActive: true,
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
      },
    });

    res.json({
      status: 'success',
      message: 'Vendor approved successfully',
      data: updatedShop,
    });
  });

  rejectVendor = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const { reason } = req.body;

    const shop = await prisma.shop.findUnique({
      where: { id },
      include: { owner: { select: { id: true, name: true, email: true } } },
    });

    if (!shop) {
      return next(new AppError('Vendor not found', 404));
    }

    // Deactivate the shop
    const updatedShop = await prisma.shop.update({
      where: { id },
      data: {
        isActive: false,
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
      },
    });

    res.json({
      status: 'success',
      message: 'Vendor rejected successfully',
      data: updatedShop,
    });
  });

  suspendVendor = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const { reason } = req.body;

    const shop = await prisma.shop.findUnique({
      where: { id },
    });

    if (!shop) {
      return next(new AppError('Vendor not found', 404));
    }

    const updatedShop = await prisma.shop.update({
      where: { id },
      data: {
        isActive: false,
      },
      include: {
        owner: { select: { id: true, name: true, email: true } },
      },
    });

    res.json({
      status: 'success',
      message: 'Vendor suspended successfully',
      data: updatedShop,
    });
  });

  // Vendor performance tracking
  getVendorPerformance = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const shop = await prisma.shop.findUnique({
      where: { id },
      include: {
        owner: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
      },
    });

    if (!shop) {
      return next(new AppError('Vendor not found', 404));
    }

    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfYear = new Date(now.getFullYear(), 0, 1);

    // Get all orders for this vendor
    type OrderWithItems = Order & {
      items: (OrderItem & {
        product: {
          id: string;
          name: string;
          price: number;
        } | null;
      })[];
      statusHistory: Array<{ timestamp: Date }>;
    };

    const allOrders: OrderWithItems[] = await prisma.order.findMany({
      where: { shopId: id },
      include: {
        items: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                price: true,
              },
            },
          },
        },
        statusHistory: {
          orderBy: { timestamp: 'desc' },
          take: 1,
        },
      },
    });

    // Calculate metrics
    const totalOrders = allOrders.length;
    const deliveredOrders = allOrders.filter((o: OrderWithItems) => o.status === 'DELIVERED').length;
    const cancelledOrders = allOrders.filter((o: OrderWithItems) => o.status === 'CANCELLED' || o.status === 'REFUNDED').length;
    const successRate = totalOrders > 0 ? ((deliveredOrders / totalOrders) * 100) : 0;

    // Revenue calculations
    const totalRevenue = allOrders
      .filter((o: OrderWithItems) => o.status === 'DELIVERED')
      .reduce((sum: number, o: OrderWithItems) => sum + Number(o.total), 0);

    const monthlyRevenue = allOrders
      .filter((o: OrderWithItems) => o.status === 'DELIVERED' && o.deliveredAt && o.deliveredAt >= startOfMonth)
      .reduce((sum: number, o: OrderWithItems) => sum + Number(o.total), 0);

    const yearlyRevenue = allOrders
      .filter((o: OrderWithItems) => o.status === 'DELIVERED' && o.deliveredAt && o.deliveredAt >= startOfYear)
      .reduce((sum: number, o: OrderWithItems) => sum + Number(o.total), 0);

    // Best-selling items
    const itemCounts: Record<string, { name: string; quantity: number; revenue: number }> = {};
    allOrders
      .filter((o: OrderWithItems) => o.status === 'DELIVERED')
      .forEach((order: OrderWithItems) => {
        order.items.forEach((item: OrderItem & { product: { id: string; name: string; price: number } | null }) => {
          const productId = item.productId;
          if (!itemCounts[productId]) {
            itemCounts[productId] = {
              name: item.productName,
              quantity: 0,
              revenue: 0,
            };
          }
          itemCounts[productId].quantity += item.quantity;
          itemCounts[productId].revenue += Number(item.totalPrice);
        });
      });

    const bestSellingItems = Object.entries(itemCounts)
      .map(([productId, data]) => ({
        productId,
        productName: data.name,
        quantitySold: data.quantity,
        revenue: data.revenue,
      }))
      .sort((a, b) => b.quantitySold - a.quantitySold)
      .slice(0, 10);

    // Get reviews
    type ReviewWithUser = Review & {
      user: {
        id: string;
        name: string;
        profilePicture: string | null;
      };
    };

    const reviews: ReviewWithUser[] = await prisma.review.findMany({
      where: { shopId: id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            profilePicture: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    // Calculate average rating from reviews
    const avgRating = reviews.length > 0
      ? reviews.reduce((sum: number, r: ReviewWithUser) => sum + r.rating, 0) / reviews.length
      : shop.rating;

    // Complaints (orders with cancellation reason or negative reviews)
    const complaints = allOrders
      .filter((o: OrderWithItems) => o.cancellationReason || o.rejectionReason)
      .map((o: OrderWithItems) => ({
        orderId: o.id,
        orderNumber: o.orderNumber,
        reason: o.cancellationReason || o.rejectionReason,
        createdAt: o.createdAt,
        status: o.status,
      }));

    const negativeReviews = reviews.filter((r: ReviewWithUser) => r.rating <= 2);

    // Payout cycle (last 30 days revenue)
    const last30Days = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const payoutAmount = allOrders
      .filter(
        (o: OrderWithItems) =>
          o.status === 'DELIVERED' &&
          o.deliveredAt &&
          o.deliveredAt >= last30Days,
      )
      .reduce((sum: number, o: OrderWithItems) => sum + Number(o.total), 0);

    res.json({
      status: 'success',
      data: {
        vendor: {
          id: shop.id,
          name: shop.name,
          email: shop.email,
          phone: shop.phone,
          rating: avgRating,
          ratingCount: reviews.length,
          isActive: shop.isActive,
          owner: shop.owner,
        },
        performance: {
          totalRevenue,
          monthlyRevenue,
          yearlyRevenue,
          totalOrders,
          deliveredOrders,
          cancelledOrders,
          successRate: Number(successRate.toFixed(2)),
          averageRating: Number(avgRating.toFixed(2)),
          totalReviews: reviews.length,
        },
        bestSellingItems,
        reviews: reviews.slice(0, 20), // Latest 20 reviews
        complaints: {
          orderComplaints: complaints,
          negativeReviews: negativeReviews.map((r: ReviewWithUser) => ({
            id: r.id,
            rating: r.rating,
            comment: r.comment,
            userName: r.user.name,
            createdAt: r.createdAt,
          })),
          total: complaints.length + negativeReviews.length,
        },
        payout: {
          last30DaysAmount: payoutAmount,
          lastPayoutDate: null, // Would need a payout table for this
          nextPayoutDate: null, // Would need payout cycle configuration
        },
      },
    });
  });

  // Category management
  getCategories = catchAsync(async (req: Request, res: Response) => {
    const categories = await prisma.category.findMany();
    res.json({ status: 'success', data: categories });
  });

  createCategory = catchAsync(async (req: Request, res: Response) => {
    if (!req.file) {
      throw new AppError('Image is required', 400);
    }

    const { shopId, ...rest } = req.body;
    if (!shopId) {
      throw new AppError('shopId is required', 400);
    }

    const filename = `category-${Date.now()}-${uuidv4()}.jpeg`;
    const filepath = path.join(config.uploadDir, filename);

    // Ensure upload directory exists
    await fs.mkdir(config.uploadDir, { recursive: true });

    // Process and save the image
    await sharp(req.file.buffer)
      .resize(800, 600)
      .toFormat('jpeg')
      .jpeg({ quality: 90 })
      .toFile(filepath);

    const category = await prisma.category.create({
      data: {
        ...rest,
        shopId,
        imageUrl: `/uploads/${filename}`,
      },
    });

    res.status(201).json({ status: 'success', data: category });
  });

  updateCategory = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const data: any = { ...req.body };

    if (req.file) {
      const filename = `category-${Date.now()}-${uuidv4()}.jpeg`;
      const filepath = path.join(config.uploadDir, filename);

      // Ensure upload directory exists
      await fs.mkdir(config.uploadDir, { recursive: true });

      // Process and save the image
      await sharp(req.file.buffer)
        .resize(800, 600)
        .toFormat('jpeg')
        .jpeg({ quality: 90 })
        .toFile(filepath);

      data.imageUrl = `/uploads/${filename}`;
    }

    const category = await prisma.category.update({
      where: { id: req.params.id },
      data,
    });

    res.json({ status: 'success', data: category });
  });

  deleteCategory = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    await prisma.category.delete({ where: { id: req.params.id } });
    res.json({ status: 'success', data: null });
  });

  // Analytics
  getUserAnalytics = catchAsync(async (req: Request, res: Response) => {
    const analytics = await prisma.user.groupBy({
      by: ['role'],
      _count: true,
    });
    res.json({ status: 'success', data: analytics });
  });

  getOrderAnalytics = catchAsync(async (req: Request, res: Response) => {
    const analytics = await prisma.order.groupBy({
      by: ['status'],
      _count: true,
      _sum: { total: true },
    });
    res.json({ status: 'success', data: analytics });
  });

  getRevenueAnalytics = catchAsync(async (req: Request, res: Response) => {
    const analytics = await prisma.order.aggregate({
      _sum: { total: true },
      _avg: { total: true },
    });
    res.json({ status: 'success', data: analytics });
  });

  // Order management
  getOrders = catchAsync(async (req: Request, res: Response) => {
    const orders = await prisma.order.findMany({
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        shop: {
          select: {
            id: true,
            name: true,
            address: true,
            phone: true,
          },
        },
        deliveryPerson: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
    res.json({ status: 'success', data: orders });
  });

  getOrderById = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const order = await prisma.order.findUnique({
      where: { id: req.params.id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        shop: {
          select: {
            id: true,
            name: true,
            address: true,
            phone: true,
          },
        },
        deliveryPerson: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true,
              },
            },
          },
        },
      },
    });
    if (!order) return next(new AppError('Order not found', 404));
    res.json({ status: 'success', data: order });
  });

  updateOrderStatus = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { status } = req.body;
    const order = await prisma.order.update({
      where: { id: req.params.id },
      data: { status },
    });
    res.json({ status: 'success', data: order });
  });

  assignDeliveryAgent = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const { deliveryPersonId } = req.body;

    // Verify delivery person exists and is active
    const deliveryPerson = await prisma.user.findUnique({
      where: { id: deliveryPersonId },
      select: { id: true, role: true, isActive: true },
    });

    if (!deliveryPerson || deliveryPerson.role !== 'DELIVERY') {
      return next(new AppError('Invalid delivery person', 400));
    }

    if (!deliveryPerson.isActive) {
      return next(new AppError('Delivery person is not active', 400));
    }

    const order = await prisma.order.update({
      where: { id },
      data: { deliveryPersonId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        shop: {
          select: {
            id: true,
            name: true,
            address: true,
            phone: true,
          },
        },
        deliveryPerson: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true,
              },
            },
          },
        },
      },
    });

    res.json({ status: 'success', data: order });
  });

  cancelOrder = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const { reason } = req.body;

    const order = await prisma.order.findUnique({
      where: { id },
      select: { status: true },
    });

    if (!order) {
      return next(new AppError('Order not found', 404));
    }

    // Prevent canceling already delivered or refunded orders
    if (order.status === 'DELIVERED' || order.status === 'REFUNDED') {
      return next(new AppError('Cannot cancel a delivered or refunded order', 400));
    }

    const updatedOrder = await prisma.order.update({
      where: { id },
      data: {
        status: 'CANCELLED',
        cancellationReason: reason,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        shop: {
          select: {
            id: true,
            name: true,
            address: true,
            phone: true,
          },
        },
        deliveryPerson: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true,
              },
            },
          },
        },
      },
    });

    res.json({ status: 'success', data: updatedOrder });
  });

  refundOrder = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const { amount, reason } = req.body;

    const order = await prisma.order.findUnique({
      where: { id },
      select: { status: true, total: true },
    });

    if (!order) {
      return next(new AppError('Order not found', 404));
    }

    // Only allow refunds for delivered or cancelled orders
    if (order.status !== 'DELIVERED' && order.status !== 'CANCELLED') {
      return next(new AppError('Order must be delivered or cancelled before refund', 400));
    }

    const refundAmount = amount ?? order.total;

    // Process refund through payment service
    const { paymentService } = await import('@/services/paymentService');
    let refundResult;
    
    try {
      const orderWithPayment = await prisma.order.findUnique({
        where: { id },
        select: { paymentId: true },
      });
      
      if (orderWithPayment?.paymentId) {
        refundResult = await paymentService.processRefund(
          orderWithPayment.paymentId,
          refundAmount,
          reason
        );
      } else {
        // For orders without payment ID (e.g., cash on delivery), create manual refund record
        refundResult = {
          success: true,
          refundId: `manual_refund_${Date.now()}`,
          amount: refundAmount,
          message: 'Manual refund processed (cash on delivery)',
        };
      }
    } catch (error: any) {
      return next(new AppError(
        error.message || 'Failed to process refund through payment gateway',
        error.statusCode || 500
      ));
    }

    const updatedOrder = await prisma.order.update({
      where: { id },
      data: {
        status: 'REFUNDED',
        cancellationReason: reason,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        shop: {
          select: {
            id: true,
            name: true,
            address: true,
            phone: true,
          },
        },
        deliveryPerson: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true,
              },
            },
          },
        },
      },
    });

    // Send notification to user
    const { NotificationService } = await import('@/services/notificationService');
    try {
      await NotificationService.sendToUser(updatedOrder.userId, {
        title: 'Refund Processed',
        body: `Refund of $${refundResult.amount.toFixed(2)} has been processed for order ${updatedOrder.orderNumber}`,
        data: { orderId: updatedOrder.id, refundId: refundResult.refundId },
      });
    } catch {}

    res.json({
      status: 'success',
      message: refundResult.message || 'Refund processed successfully',
      data: updatedOrder,
      refundAmount: refundResult.amount,
      refundId: refundResult.refundId,
    });
  });

  updateOrderFees = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
    const { deliveryFee, discount, reason } = req.body;

    const order = await prisma.order.findUnique({
      where: { id },
      select: { status: true, subtotal: true, deliveryFee: true, discount: true, tax: true, serviceFee: true },
    });

    if (!order) {
      return next(new AppError('Order not found', 404));
    }

    // Prevent updating fees for delivered or cancelled orders
    if (order.status === 'DELIVERED' || order.status === 'CANCELLED' || order.status === 'REFUNDED') {
      return next(new AppError('Cannot update fees for delivered, cancelled, or refunded orders', 400));
    }

    const newDeliveryFee = deliveryFee ?? order.deliveryFee;
    const newDiscount = discount ?? order.discount;
    const newSubtotal = order.subtotal - (newDiscount - order.discount);
    const newTotal = newSubtotal + newDeliveryFee + order.serviceFee + order.tax;

    const updatedOrder = await prisma.order.update({
      where: { id },
      data: {
        deliveryFee: newDeliveryFee,
        discount: newDiscount,
        subtotal: newSubtotal,
        total: newTotal,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        shop: {
          select: {
            id: true,
            name: true,
            address: true,
            phone: true,
          },
        },
        deliveryPerson: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        items: {
          include: {
            product: {
              select: {
                name: true,
                price: true,
              },
            },
          },
        },
      },
    });

    res.json({ status: 'success', data: updatedOrder });
  });

  getAvailableDeliveryAgents = catchAsync(async (req: Request, res: Response) => {
    const agents = await prisma.user.findMany({
      where: {
        role: 'DELIVERY',
        isActive: true,
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
      },
      orderBy: {
        name: 'asc',
      },
    });

    res.json({ status: 'success', data: agents });
  });
} 
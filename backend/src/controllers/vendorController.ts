import { Response } from 'express';
import { OrderStatus } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';
import { catchAsync } from '@/utils/catchAsync';
import { prisma } from '@/config/database';
import { getIO } from '@/services/socketService';
import { NotificationService } from '@/services/notificationService';

export class VendorController {
  // Shop Management
  async getShop(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: {
        ownerId: req.user!.id
      }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    res.json(shop);
  }

  async updateShop(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { name, description, logoUrl } = req.body;

    const updatedShop = await prisma.shop.update({
      where: { id: shop.id },
      data: {
        name,
        description,
        logoUrl,
        isActive: true
      }
    });

    res.json(updatedShop);
  }

  // Product Management
  async getProducts(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: {
        ownerId: req.user!.id
      }
    });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const products = await prisma.product.findMany({
      where: {
        shopId: shop.id
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json(products);
  }

  async createProduct(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { name, description, price, categoryId, categoryName, images, imageUrl, inStock, isAvailable } = req.body;

    // Find or create category
    let category;
    if (categoryId) {
      category = await prisma.category.findUnique({ 
        where: { id: categoryId } 
      });
    }

    // If categoryId doesn't exist or categoryName is provided, find or create by name
    if (!category && categoryName) {
      category = await prisma.category.findFirst({
        where: {
          shopId: shop.id,
          name: {
            equals: categoryName,
            mode: 'insensitive'
          }
        }
      });

      // Create category if it doesn't exist
      if (!category) {
        category = await prisma.category.create({
          data: {
            name: categoryName,
            description: `${categoryName} category`,
            shopId: shop.id,
            status: 'ACTIVE'
          }
        });
      }
    }

    if (!category) {
      throw new AppError('Category is required. Please provide categoryId or categoryName', 400);
    }

    // Handle availability - use inStock if provided, otherwise isAvailable, default to true
    const productInStock = inStock !== undefined ? inStock : (isAvailable !== undefined ? isAvailable : true);

    const product = await prisma.product.create({
      data: {
        name,
        description,
        price,
        categoryId: category.id,
        images: images ?? [],
        imageUrl: imageUrl ?? null,
        categoryName: category.name,
        inStock: productInStock,
        isActive: productInStock, // Set isActive to match inStock
        shopId: shop.id
      }
    });

    res.status(201).json({ status: 'success', data: product });
  }

  async updateProduct(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { id } = req.params;
    const { name, description, price, categoryId, categoryName, images, imageUrl, inStock, isAvailable } = req.body;

    // Find or create category if categoryName is provided
    let category;
    if (categoryName) {
      category = await prisma.category.findFirst({
        where: {
          shopId: shop.id,
          name: {
            equals: categoryName,
            mode: 'insensitive'
          }
        }
      });

      // Create category if it doesn't exist
      if (!category) {
        category = await prisma.category.create({
          data: {
            name: categoryName,
            description: `${categoryName} category`,
            shopId: shop.id,
            status: 'ACTIVE'
          }
        });
      }
    } else if (categoryId) {
      category = await prisma.category.findUnique({ 
        where: { id: categoryId } 
      });
    }

    // Build update data - only include fields that are provided
    const updateData: any = {};
    
    if (name !== undefined) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (price !== undefined) updateData.price = price;
    if (images !== undefined) updateData.images = images;
    if (imageUrl !== undefined) updateData.imageUrl = imageUrl || null;
    
    // Handle availability - use inStock if provided, otherwise isAvailable
    if (inStock !== undefined) {
      updateData.inStock = inStock;
      updateData.isActive = inStock; // Keep isActive in sync with inStock
    } else if (isAvailable !== undefined) {
      updateData.inStock = isAvailable;
      updateData.isActive = isAvailable;
    }

    if (category) {
      updateData.categoryId = category.id;
      updateData.categoryName = category.name;
    }

    const product = await prisma.product.update({
      where: {
        id,
        shopId: shop.id
      },
      data: updateData
    });

    if (!product) {
      throw new AppError('Product not found', 404);
    }

    res.json({ status: 'success', data: product });
  }

  async deleteProduct(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { id } = req.params;

    const product = await prisma.product.delete({
      where: {
        id,
        shopId: shop.id
      }
    });

    if (!product) {
      throw new AppError('Product not found', 404);
    }

    res.json({ message: 'Product deleted successfully' });
  }

  // Order Management
  async getVendorOrders(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const orders = await prisma.order.findMany({
      where: {
        shopId: shop.id
      },
      include: {
        user: {
          select: {
            name: true,
            phone: true,
            addresses: true
          }
        },
        items: {
          include: {
            product: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json(orders);
  }

  async updateOrderStatus(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { id } = req.params;
    const { status } = req.body;

    const order = await prisma.order.update({
      where: {
        id,
        shopId: shop.id
      },
      data: {
        status: status as OrderStatus
      }
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    // Notify user and shop
    try {
      const io = getIO();
      if (io) {
        io.to(`order:${order.id}`).emit('order:status', { orderId: order.id, status: order.status });
        io.to(`user:${order.userId}`).emit('order:status', { orderId: order.id, status: order.status });
      }
      await NotificationService.sendToUser(order.userId, {
        title: 'Order Update',
        body: `Your order status is now ${order.status}`,
        data: { orderId: order.id },
      });
    } catch {}

    res.json(order);
  }

  async getOrderStats(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({ where: { ownerId: req.user!.id } });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const stats = await prisma.order.aggregate({
      where: { shopId: shop.id },
      _count: { id: true },
      _sum: { total: true },
      _avg: { total: true }
    });

    res.json(stats);
  }

  // Analytics
  async getSalesAnalytics(req: AuthenticatedRequest, res: Response) {
    const { startDate, endDate, period } = req.query;

    const shop = await prisma.shop.findFirst({ where: { ownerId: req.user!.id } });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const now = new Date();
    let startDateFilter: Date | undefined;
    let endDateFilter: Date | undefined;

    // Calculate date range based on period
    if (period === 'today') {
      startDateFilter = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      endDateFilter = now;
    } else if (period === 'week') {
      startDateFilter = new Date(now);
      startDateFilter.setDate(now.getDate() - now.getDay());
      startDateFilter.setHours(0, 0, 0, 0);
      endDateFilter = now;
    } else if (period === 'month') {
      startDateFilter = new Date(now.getFullYear(), now.getMonth(), 1);
      endDateFilter = now;
    } else if (startDate && endDate) {
      startDateFilter = new Date(startDate as string);
      endDateFilter = new Date(endDate as string);
    }

    const EXCLUDED_REVENUE_STATUSES = [OrderStatus.CANCELLED, OrderStatus.REFUNDED];
    const where: any = {
      shopId: shop.id,
      status: { notIn: EXCLUDED_REVENUE_STATUSES },
    };

    if (startDateFilter && endDateFilter) {
      where.createdAt = { gte: startDateFilter, lte: endDateFilter };
    }

    // Get revenue trends for last 7 days
    const last7Days = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(now);
      date.setDate(now.getDate() - i);
      const dayStart = new Date(date.getFullYear(), date.getMonth(), date.getDate());
      const dayEnd = new Date(dayStart);
      dayEnd.setHours(23, 59, 59, 999);

      const dayRevenue = await prisma.order.aggregate({
        where: {
          shopId: shop.id,
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
          createdAt: { gte: dayStart, lte: dayEnd },
        },
        _sum: { total: true },
        _count: { id: true },
      });

      last7Days.push({
        date: dayStart.toISOString().split('T')[0],
        revenue: dayRevenue._sum.total ?? 0,
        orders: dayRevenue._count.id ?? 0,
      });
    }

    const sales = await prisma.order.aggregate({
      where,
      _count: { id: true },
      _sum: { total: true },
      _avg: { total: true },
    });

    res.json({
      status: 'success',
      data: {
        ...sales,
        revenueTrend: last7Days,
      },
    });
  }

  async getProductAnalytics(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({ where: { ownerId: req.user!.id } });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const EXCLUDED_REVENUE_STATUSES = [OrderStatus.CANCELLED, OrderStatus.REFUNDED];

    // Top products by revenue for the vendor's shop
    const products = await prisma.orderItem.groupBy({
      by: ['productId', 'productName'],
      where: {
        order: {
          shopId: shop.id,
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
      },
      _sum: { totalPrice: true, quantity: true },
      _count: { id: true },
      orderBy: {
        _sum: { totalPrice: 'desc' },
      },
      take: 10,
    });

    // Format the response
    const formattedProducts = products.map((product: any) => ({
      productId: product.productId,
      productName: product.productName,
      totalRevenue: product._sum.totalPrice ?? 0,
      totalQuantity: product._sum.quantity ?? 0,
      orderCount: product._count.id,
    }));

    res.json({
      status: 'success',
      data: formattedProducts,
    });
  }

  async getPerformanceAnalytics(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({ where: { ownerId: req.user!.id } });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    // Get orders with status history for prep time calculation
    const ordersWithHistory = await prisma.order.findMany({
      where: {
        shopId: shop.id,
        status: { in: [OrderStatus.READY_FOR_PICKUP, OrderStatus.IN_DELIVERY, OrderStatus.DELIVERED] },
      },
      include: {
        statusHistory: {
          orderBy: { timestamp: 'asc' },
        },
      },
      take: 100, // Analyze last 100 completed orders
    });

    // Calculate average preparation time (from ACCEPTED/PREPARING to READY_FOR_PICKUP)
    let totalPrepTime = 0;
    let prepTimeCount = 0;
    const peakHours: Record<number, number> = {};
    let totalOrders = 0;
    let accurateOrders = 0;

    for (const order of ordersWithHistory) {
      // Calculate prep time
      const acceptedTime = order.statusHistory.find((h: any) => 
        h.status === OrderStatus.ACCEPTED || h.status === OrderStatus.PREPARING
      )?.timestamp;
      const readyTime = order.statusHistory.find((h: any) => 
        h.status === OrderStatus.READY_FOR_PICKUP
      )?.timestamp;

      if (acceptedTime && readyTime) {
        const prepTimeMinutes = (readyTime.getTime() - acceptedTime.getTime()) / (1000 * 60);
        totalPrepTime += prepTimeMinutes;
        prepTimeCount++;
      }

      // Calculate peak hours
      const orderHour = order.createdAt.getHours();
      peakHours[orderHour] = (peakHours[orderHour] || 0) + 1;

      // Calculate order accuracy (orders that weren't cancelled or refunded)
      totalOrders++;
      if (order.status !== OrderStatus.CANCELLED && order.status !== OrderStatus.REFUNDED) {
        accurateOrders++;
      }
    }

    const avgPrepTimeMinutes = prepTimeCount > 0 ? Math.round(totalPrepTime / prepTimeCount) : 0;
    const orderAccuracy = totalOrders > 0 ? Math.round((accurateOrders / totalOrders) * 100) : 100;

    // Format peak hours data (24 hours)
    const peakHoursData = Array.from({ length: 24 }, (_, hour) => ({
      hour,
      count: peakHours[hour] || 0,
    }));

    // Find peak hour
    const peakHour = peakHoursData.reduce((max, current) => 
      current.count > max.count ? current : max, peakHoursData[0]
    );

    res.json({
      status: 'success',
      data: {
        avgPrepTimeMinutes,
        orderAccuracy,
        peakHours: peakHoursData,
        peakHour: peakHour.hour,
        peakHourCount: peakHour.count,
      },
    });
  }

  getVendorShop = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id },
      include: { categories: true },
    });
    
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    // Calculate analytics data
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const EXCLUDED_REVENUE_STATUSES = [OrderStatus.CANCELLED, OrderStatus.REFUNDED];

    const [
      todayOrders,
      weekOrders,
      monthOrders,
      totalOrders,
      todayRevenueAgg,
      weekRevenueAgg,
      monthRevenueAgg,
      totalRevenueAgg,
      pendingOrders,
      preparingOrders,
      readyOrders,
      completedToday,
    ] = await Promise.all([
      prisma.order.count({
        where: {
          shopId: shop.id,
          createdAt: { gte: startOfToday },
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
      }),
      prisma.order.count({
        where: {
          shopId: shop.id,
          createdAt: { gte: startOfWeek },
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
      }),
      prisma.order.count({
        where: {
          shopId: shop.id,
          createdAt: { gte: startOfMonth },
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
      }),
      prisma.order.count({
        where: {
          shopId: shop.id,
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
      }),
      prisma.order.aggregate({
        where: {
          shopId: shop.id,
          createdAt: { gte: startOfToday },
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
        _sum: { total: true },
      }),
      prisma.order.aggregate({
        where: {
          shopId: shop.id,
          createdAt: { gte: startOfWeek },
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
        _sum: { total: true },
      }),
      prisma.order.aggregate({
        where: {
          shopId: shop.id,
          createdAt: { gte: startOfMonth },
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
        _sum: { total: true },
      }),
      prisma.order.aggregate({
        where: {
          shopId: shop.id,
          status: { notIn: EXCLUDED_REVENUE_STATUSES },
        },
        _sum: { total: true },
      }),
      prisma.order.count({
        where: {
          shopId: shop.id,
          status: OrderStatus.PENDING,
        },
      }),
      prisma.order.count({
        where: {
          shopId: shop.id,
          status: OrderStatus.PREPARING,
        },
      }),
      prisma.order.count({
        where: {
          shopId: shop.id,
          status: OrderStatus.READY_FOR_PICKUP,
        },
      }),
      prisma.order.count({
        where: {
          shopId: shop.id,
          status: OrderStatus.DELIVERED,
          deliveredAt: { gte: startOfToday },
        },
      }),
    ]);

    const todayRevenue = todayRevenueAgg._sum.total ?? 0;
    const weekRevenue = weekRevenueAgg._sum.total ?? 0;
    const monthRevenue = monthRevenueAgg._sum.total ?? 0;
    const totalRevenue = totalRevenueAgg._sum.total ?? 0;
    const averageOrderValue = todayOrders > 0 ? todayRevenue / todayOrders : 0;

    res.json({
      status: 'success',
      data: {
        ...shop,
        // Analytics data
        todayOrders,
        weekOrders,
        monthOrders,
        totalOrders,
        todayRevenue,
        weekRevenue,
        monthRevenue,
        totalRevenue,
        averageOrderValue,
        pendingOrders,
        preparingOrders,
        readyOrders,
        completedOrders: completedToday,
        rating: shop.rating ?? 0,
        ratingCount: shop.reviewCount ?? 0,
      },
    });
  });

  createShop = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    // Check if vendor already has a shop
    const existingShop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id },
    });
    
    if (existingShop) {
      throw new AppError('Shop already exists', 400);
    }

    const {
      name,
      description,
      category,
      address,
      latitude,
      longitude,
      phone,
      email,
      openingHours,
      hasDelivery = true,
      hasPickup = true,
      minimumOrderAmount = 0,
      deliveryFee = 0,
      estimatedDeliveryTime = 30
    } = req.body;

    const shop = await prisma.shop.create({
      data: {
        name,
        description,
        category,
        address,
        latitude,
        longitude,
        phone,
        email,
        openingHours,
        hasDelivery,
        hasPickup,
        minimumOrderAmount,
        deliveryFee,
        estimatedDeliveryTime,
        ownerId: req.user!.id,
        isActive: true,
        isOpen: true,
      },
      include: { categories: true },
    });

    res.status(201).json({ status: 'success', data: shop });
  });

  toggleShopStatus = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id },
    });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }
    const updatedShop = await prisma.shop.update({
      where: { id: shop.id },
      data: { isActive: !shop.isActive },
    });
    res.json({ status: 'success', data: updatedShop });
  });

  getVendorProducts = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id },
    });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }
    const products = await prisma.product.findMany({
      where: { shopId: shop.id },
      include: { category: true },
    });
    res.json({ status: 'success', data: products });
  });

  async handleCancellationRequest(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { id } = req.params;
    const { action } = req.body; // 'approve' or 'reject'

    const order = await prisma.order.findFirst({
      where: {
        id,
        shopId: shop.id,
        status: OrderStatus.CANCELLATION_REQUESTED
      }
    });

    if (!order) {
      throw new AppError('Order not found or not in cancellation requested status', 404);
    }

    const updatedOrder = await prisma.order.update({
      where: {
        id: order.id
      },
      data: {
        status: action === 'approve' ? OrderStatus.CANCELLED : OrderStatus.PENDING,
        cancellationReason: action === 'approve' ? 
          'Cancellation approved by vendor' : 
          'Cancellation request rejected by vendor'
      }
    });
    // Emit events and push notification
    try {
      const io = getIO();
      if (io) {
        const event = action === 'approve' ? 'order:cancellation_approved' : 'order:cancellation_rejected';
        io.to(`order:${updatedOrder.id}`).emit(event, { orderId: updatedOrder.id });
        io.to(`user:${updatedOrder.userId}`).emit(event, { orderId: updatedOrder.id });
        io.to(`shop:${updatedOrder.shopId}`).emit(event, { orderId: updatedOrder.id });
      }
      await NotificationService.sendToUser(updatedOrder.userId, {
        title: 'Cancellation update',
        body: action === 'approve' ? 'Your cancellation was approved' : 'Your cancellation request was rejected',
        data: { orderId: updatedOrder.id },
      });
    } catch {}

    res.json(updatedOrder);
  }

  async cancelOrder(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { id } = req.params;
    const { reason } = req.body;

    const order = await prisma.order.findFirst({
      where: {
        id,
        shopId: shop.id,
        status: {
          in: [OrderStatus.PENDING, OrderStatus.ACCEPTED, OrderStatus.PREPARING]
        }
      }
    });

    if (!order) {
      throw new AppError('Order not found or cannot be cancelled in current status', 404);
    }

    const updatedOrder = await prisma.order.update({
      where: {
        id: order.id
      },
      data: {
        status: OrderStatus.CANCELLED,
        cancellationReason: reason || 'Cancelled by vendor'
      }
    });

    res.json(updatedOrder);
  }
} 
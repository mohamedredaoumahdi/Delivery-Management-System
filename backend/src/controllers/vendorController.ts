import { Response } from 'express';
import { PrismaClient, OrderStatus } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';
import { catchAsync } from '@/utils/catchAsync';
import { prisma } from '@/config/database';

const prismaClient = new PrismaClient();

export class VendorController {
  // Shop Management
  async getShop(req: AuthenticatedRequest, res: Response) {
    const shop = await prismaClient.shop.findFirst({
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
    const shop = await prismaClient.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { name, description, logoUrl } = req.body;

    const updatedShop = await prismaClient.shop.update({
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

    const { name, description, price, categoryId, images } = req.body;

    const product = await prisma.product.create({
      data: {
        name,
        description,
        price,
        categoryId,
        images,
        categoryName: (await prisma.category.findUnique({ where: { id: categoryId } }))!.name,
        shopId: shop.id
      }
    });

    res.status(201).json(product);
  }

  async updateProduct(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id }
    });

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const { id } = req.params;
    const { name, description, price, categoryId, images } = req.body;

    const product = await prisma.product.update({
      where: {
        id,
        shopId: shop.id
      },
      data: {
        name,
        description,
        price,
        categoryId,
        images
      }
    });

    if (!product) {
      throw new AppError('Product not found', 404);
    }

    res.json(product);
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

    res.json(order);
  }

  async getOrderStats(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: {
        ownerId: req.user!.id
      }
    });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const stats = await prisma.order.aggregate({
      _count: {
        id: true
      },
      _sum: {
        total: true
      },
      _avg: {
        total: true
      }
    });

    res.json(stats);
  }

  // Analytics
  async getSalesAnalytics(req: AuthenticatedRequest, res: Response) {
    const { startDate, endDate } = req.query;

    const where: any = {
      shopId: req.user!.id,
      status: OrderStatus.DELIVERED
    };

    if (startDate && endDate) {
      where.deliveredAt = {
        gte: new Date(startDate as string),
        lte: new Date(endDate as string)
      };
    }

    const sales = await prisma.order.aggregate({
      _count: {
        id: true
      },
      _sum: {
        total: true
      },
      _avg: {
        total: true
      }
    });

    res.json(sales);
  }

  async getProductAnalytics(req: AuthenticatedRequest, res: Response) {
    const shop = await prisma.shop.findFirst({
      where: {
        ownerId: req.user!.id
      }
    });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const products = await prisma.order.aggregate({
      _count: {
        id: true
      },
      _sum: {
        total: true
      },
      _avg: {
        total: true
      }
    });

    res.json(products);
  }

  getVendorShop = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const shop = await prisma.shop.findFirst({
      where: { ownerId: req.user!.id },
      include: { categories: true },
    });
    res.json({ status: 'success', data: shop });
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
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';

const prisma = new PrismaClient();

export class ShopController {
  getShops = catchAsync(async (req: Request, res: Response) => {
    const shops = await prisma.shop.findMany({
      where: { isActive: true },
      orderBy: { rating: 'desc' },
    });
    return res.json(shops);
  });

  getFeaturedShops = catchAsync(async (req: Request, res: Response) => {
    const shops = await prisma.shop.findMany({
      where: {
        isActive: true,
        isFeatured: true,
      },
      orderBy: { rating: 'desc' },
      take: 10,
    });
    return res.json(shops);
  });

  getNearbyShops = catchAsync(async (req: Request, res: Response) => {
    const { lat, lng, radius = 5 } = req.query;
    
    if (!lat || !lng) {
      throw new AppError('Location coordinates are required', 400);
    }

    // Note: This is a simplified version. For actual geospatial queries,
    // you'll need to use Prisma's geospatial features or a specialized service
    const shops = await prisma.shop.findMany({
      where: {
        isActive: true,
        // Add geospatial query here when needed
      },
      take: 20,
    });

    return res.json(shops);
  });

  getShopById = catchAsync(async (req: Request, res: Response) => {
    const shop = await prisma.shop.findUnique({
      where: { id: req.params.id },
    });
    
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    return res.json(shop);
  });

  getShopProducts = catchAsync(async (req: Request, res: Response) => {
    const products = await prisma.product.findMany({
      where: {
        shopId: req.params.id,
        isActive: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return res.json(products);
  });

  getShopCategories = catchAsync(async (req: Request, res: Response) => {
    const categories = await prisma.category.findMany({
      where: {
        shopId: req.params.id,
        status: 'ACTIVE',
      },
      orderBy: { name: 'asc' },
    });

    return res.json(categories);
  });
} 
import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { boundingBox, haversineKm } from '@/utils/geo';
import { catchAsync } from '@/utils/catchAsync';

// Use shared Prisma client to avoid multiple connections
import { prisma } from '@/config/database';

export class ShopController {
  getShops = catchAsync(async (req: Request, res: Response) => {
    const { 
      q: query, 
      category, 
      lat, 
      lng, 
      radius, 
      page = 1, 
      limit = 20 
    } = req.query;

    // Build where clause
    const where: any = { isActive: true };

    // Add category filter
    if (category && typeof category === 'string') {
      where.category = category.toUpperCase();
    }

    // Add search query filter - only search by shop name
    if (query && typeof query === 'string') {
      where.name = { contains: query, mode: 'insensitive' };
    }

    // Calculate pagination
    const skip = (Number(page) - 1) * Number(limit);
    const take = Number(limit);

    const shops = await prisma.shop.findMany({
      where,
      orderBy: { rating: 'desc' },
      skip,
      take,
    });

    return res.json({ status: 'success', data: shops });
  });

  getFeaturedShops = catchAsync(async (req: Request, res: Response) => {
    const { limit = 10 } = req.query;
    
    const shops = await prisma.shop.findMany({
      where: {
        isActive: true,
        isFeatured: true,
      },
      orderBy: { rating: 'desc' },
      take: Number(limit),
    });
    return res.json({ status: 'success', data: shops });
  });

  getNearbyShops = catchAsync(async (req: Request, res: Response) => {
    const { lat, lng, radius = 5 } = req.query;
    
    if (!lat || !lng) {
      throw new AppError('Location coordinates are required', 400);
    }

    const latNum = Number(lat);
    const lngNum = Number(lng);
    const radiusKm = Number(radius);

    // Pre-filter using bounding box to reduce result set
    const box = boundingBox(latNum, lngNum, radiusKm);
    const candidates = await prisma.shop.findMany({
      where: {
        isActive: true,
        latitude: { gte: box.minLat, lte: box.maxLat },
        longitude: { gte: box.minLon, lte: box.maxLon },
      },
      take: 200,
    });

    // Precise filter using Haversine
    const shops = candidates
      .map((s: any) => ({
        ...s,
        distanceKm: haversineKm(latNum, lngNum, s.latitude, s.longitude),
      }))
      .filter((s: any) => s.distanceKm <= radiusKm)
      .sort((a: any, b: any) => a.distanceKm - b.distanceKm)
      .slice(0, 50);

    return res.json({ status: 'success', data: shops });
  });

  getShopById = catchAsync(async (req: Request, res: Response) => {
    const shop = await prisma.shop.findUnique({
      where: { id: req.params.id },
    });
    
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    return res.json({ status: 'success', data: shop });
  });

  getShopProducts = catchAsync(async (req: Request, res: Response) => {
    const { 
      q: query, 
      category, 
      in_stock: inStock,
      featured,
      page = 1, 
      limit = 20 
    } = req.query;

    // Build where clause
    const where: any = {
      shopId: req.params.id,
      isActive: true,
    };

    // Add category filter
    if (category && typeof category === 'string') {
      where.categoryName = {
        equals: category,
        mode: 'insensitive'
      };
    }

    // Add search query filter
    if (query && typeof query === 'string') {
      where.OR = [
        { name: { contains: query, mode: 'insensitive' } },
        { description: { contains: query, mode: 'insensitive' } },
        { tags: { has: query } },
      ];
    }

    // Add stock filter
    if (inStock !== undefined) {
      where.inStock = inStock === 'true';
    }

    // Add featured filter
    if (featured !== undefined) {
      where.isFeatured = featured === 'true';
    }

    // Calculate pagination
    const skip = (Number(page) - 1) * Number(limit);
    const take = Number(limit);

    const products = await prisma.product.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take,
    });

    return res.json({ status: 'success', data: products });
  });

  getShopCategories = catchAsync(async (req: Request, res: Response) => {
    const categories = await prisma.category.findMany({
      where: {
        shopId: req.params.id,
        status: 'ACTIVE',
      },
      orderBy: { name: 'asc' },
    });

    return res.json({ status: 'success', data: categories });
  });
} 
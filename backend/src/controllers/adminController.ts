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

export class AdminController {
  // User management
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
} 
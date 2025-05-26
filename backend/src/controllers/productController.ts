import { Request, Response, NextFunction } from 'express';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { AuthenticatedRequest } from '@/types/express';

export class ProductController {
  getProducts = catchAsync(async (req: Request, res: Response) => {
    const products = await prisma.product.findMany({
      include: {
        shop: true,
        category: true,
      },
    });

    res.json({
      status: 'success',
      data: products,
    });
  });

  getProductById = catchAsync(async (req: Request, res: Response, next: NextFunction) => {
    const product = await prisma.product.findUnique({
      where: { id: req.params.id },
      include: {
        shop: true,
        category: true,
      },
    });

    if (!product) {
      return next(new AppError('Product not found', 404));
    }

    res.json({
      status: 'success',
      data: product,
    });
  });

  getProductsByCategory = catchAsync(async (req: Request, res: Response) => {
    const products = await prisma.product.findMany({
      where: { categoryId: req.params.categoryId },
      include: {
        shop: true,
        category: true,
      },
    });

    res.json({
      status: 'success',
      data: products,
    });
  });

  getProductsByShop = catchAsync(async (req: Request, res: Response) => {
    const products = await prisma.product.findMany({
      where: { shopId: req.params.shopId },
      include: {
        category: true,
      },
    });

    res.json({
      status: 'success',
      data: products,
    });
  });

  createProduct = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { name, description, price, categoryId, shopId } = req.body;
    const images = req.body.images || [];

    const category = await prisma.category.findUnique({ where: { id: categoryId } });
    if (!category) throw new AppError('Category not found', 404);

    const product = await prisma.product.create({
      data: {
        name,
        description,
        price: parseFloat(price),
        categoryId,
        shopId,
        images,
        categoryName: category.name,
      },
    });

    res.status(201).json({
      status: 'success',
      data: product,
    });
  });

  updateProduct = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const { name, description, price, categoryId, tags, nutritionalInfo, inStock, stockQuantity } = req.body;
    const images = (req.files as Express.Multer.File[])?.map(file => file.path);

    const product = await prisma.product.update({
      where: { id: req.params.id },
      data: {
        name,
        description,
        price: price ? parseFloat(price) : undefined,
        categoryId,
        images: images ? { set: images } : undefined,
        tags: tags ? { set: tags } : undefined,
        nutritionalInfo: nutritionalInfo ? nutritionalInfo : undefined,
        inStock,
        stockQuantity,
        updatedAt: new Date()
      },
    });

    res.json({
      status: 'success',
      data: product,
    });
  });

  deleteProduct = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    await prisma.product.delete({
      where: { id: req.params.id },
    });

    res.json({
      status: 'success',
      data: null,
    });
  });

  updateProductStatus = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const { isActive } = req.body;

    const product = await prisma.product.update({
      where: { id: req.params.id },
      data: { isActive },
    });

    res.json({
      status: 'success',
      data: product,
    });
  });
} 
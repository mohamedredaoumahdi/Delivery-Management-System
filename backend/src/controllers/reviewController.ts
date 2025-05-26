import { Request, Response, NextFunction } from 'express';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { AuthenticatedRequest } from '@/types/express';

export class ReviewController {
  createReview = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { rating, comment, shopId, productId } = req.body;
    const review = await prisma.review.create({
      data: {
        rating,
        comment,
        shopId,
        productId,
        userId: req.user!.id,
      },
    });
    res.status(201).json({ status: 'success', data: review });
  });

  updateReview = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const review = await prisma.review.update({
      where: { id: req.params.id },
      data: req.body,
    });
    res.json({ status: 'success', data: review });
  });

  deleteReview = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    await prisma.review.delete({ where: { id: req.params.id } });
    res.json({ status: 'success', data: null });
  });

  getShopReviews = catchAsync(async (req: Request, res: Response) => {
    const reviews = await prisma.review.findMany({
      where: { shopId: req.params.shopId },
      include: { user: true },
    });
    res.json({ status: 'success', data: reviews });
  });

  getProductReviews = catchAsync(async (req: Request, res: Response) => {
    const reviews = await prisma.review.findMany({
      where: { productId: req.params.productId },
      include: { user: true },
    });
    res.json({ status: 'success', data: reviews });
  });

  getUserReviews = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const reviews = await prisma.review.findMany({
      where: { userId: req.user!.id },
      include: { shop: true, product: true },
    });
    res.json({ status: 'success', data: reviews });
  });
} 
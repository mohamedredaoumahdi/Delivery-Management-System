import { Response } from 'express';
import { PrismaClient, PaymentMethodType } from '@prisma/client';
import { AppError } from '@/utils/appError';
import { AuthenticatedRequest } from '../types/express';
import { logger } from '@/utils/logger';

const prisma = new PrismaClient();

export class PaymentMethodController {
  /**
   * Get all payment methods for the authenticated user
   */
  async getPaymentMethods(req: AuthenticatedRequest, res: Response) {
    logger.info('💳 PaymentMethodController: Getting user payment methods');
    
    const userId = req.user!.id;
    
    const paymentMethods = await prisma.userPaymentMethod.findMany({
      where: { 
        userId,
        isActive: true 
      },
      orderBy: [
        { isDefault: 'desc' },
        { createdAt: 'desc' }
      ]
    });
    
    logger.info(`💳 ✅ PaymentMethodController: Successfully fetched ${paymentMethods.length} payment methods`);
    
    res.json({
      status: 'success',
      data: paymentMethods
    });
  }

  /**
   * Create a new payment method for the authenticated user
   */
  async createPaymentMethod(req: AuthenticatedRequest, res: Response) {
    logger.info('💳 PaymentMethodController: Creating new payment method');
    
    const userId = req.user!.id;
    const {
      type,
      label,
      cardLast4,
      cardBrand,
      cardExpiryMonth,
      cardExpiryYear,
      cardHolderName,
      walletEmail,
      walletProvider,
      bankName,
      bankAccountLast4,
      isDefault = false
    } = req.body;

    // If this is going to be the default payment method, unset others
    if (isDefault) {
      await prisma.userPaymentMethod.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false }
      });
    }

    // If user has no payment methods, make this the default
    const existingCount = await prisma.userPaymentMethod.count({
      where: { userId, isActive: true }
    });
    
    const shouldBeDefault = isDefault || existingCount === 0;

    const paymentMethod = await prisma.userPaymentMethod.create({
      data: {
        type,
        label,
        cardLast4,
        cardBrand,
        cardExpiryMonth,
        cardExpiryYear,
        cardHolderName,
        walletEmail,
        walletProvider,
        bankName,
        bankAccountLast4,
        isDefault: shouldBeDefault,
        userId
      }
    });

    logger.info(`💳 ✅ PaymentMethodController: Successfully created payment method ${paymentMethod.id}`);
    
    res.status(201).json({
      status: 'success',
      data: paymentMethod
    });
  }

  /**
   * Update a payment method
   */
  async updatePaymentMethod(req: AuthenticatedRequest, res: Response) {
    logger.info('💳 PaymentMethodController: Updating payment method');
    
    const userId = req.user!.id;
    const { paymentMethodId } = req.params;
    const {
      label,
      cardExpiryMonth,
      cardExpiryYear,
      cardHolderName,
      walletEmail,
      bankName,
      isDefault
    } = req.body;

    // Check if payment method exists and belongs to user
    const existingPaymentMethod = await prisma.userPaymentMethod.findFirst({
      where: {
        id: paymentMethodId,
        userId,
        isActive: true
      }
    });

    if (!existingPaymentMethod) {
      throw new AppError('Payment method not found', 404);
    }

    // If setting as default, unset others
    if (isDefault) {
      await prisma.userPaymentMethod.updateMany({
        where: { userId, isDefault: true },
        data: { isDefault: false }
      });
    }

    const updatedPaymentMethod = await prisma.userPaymentMethod.update({
      where: { id: paymentMethodId },
      data: {
        label,
        cardExpiryMonth,
        cardExpiryYear,
        cardHolderName,
        walletEmail,
        bankName,
        isDefault
      }
    });

    logger.info(`💳 ✅ PaymentMethodController: Successfully updated payment method ${paymentMethodId}`);
    
    res.json({
      status: 'success',
      data: updatedPaymentMethod
    });
  }

  /**
   * Delete a payment method
   */
  async deletePaymentMethod(req: AuthenticatedRequest, res: Response) {
    logger.info('💳 PaymentMethodController: Deleting payment method');
    
    const userId = req.user!.id;
    const { paymentMethodId } = req.params;

    // Check if payment method exists and belongs to user
    const existingPaymentMethod = await prisma.userPaymentMethod.findFirst({
      where: {
        id: paymentMethodId,
        userId,
        isActive: true
      }
    });

    if (!existingPaymentMethod) {
      throw new AppError('Payment method not found', 404);
    }

    // Soft delete by setting isActive to false
    await prisma.userPaymentMethod.update({
      where: { id: paymentMethodId },
      data: { isActive: false }
    });

    // If this was the default payment method, set another one as default
    if (existingPaymentMethod.isDefault) {
      const nextPaymentMethod = await prisma.userPaymentMethod.findFirst({
        where: {
          userId,
          isActive: true,
          id: { not: paymentMethodId }
        },
        orderBy: { createdAt: 'desc' }
      });

      if (nextPaymentMethod) {
        await prisma.userPaymentMethod.update({
          where: { id: nextPaymentMethod.id },
          data: { isDefault: true }
        });
      }
    }

    logger.info(`💳 ✅ PaymentMethodController: Successfully deleted payment method ${paymentMethodId}`);
    
    res.json({
      status: 'success',
      message: 'Payment method deleted successfully'
    });
  }

  /**
   * Set a payment method as default
   */
  async setDefaultPaymentMethod(req: AuthenticatedRequest, res: Response) {
    logger.info('💳 PaymentMethodController: Setting default payment method');
    
    const userId = req.user!.id;
    const { paymentMethodId } = req.params;

    // Check if payment method exists and belongs to user
    const existingPaymentMethod = await prisma.userPaymentMethod.findFirst({
      where: {
        id: paymentMethodId,
        userId,
        isActive: true
      }
    });

    if (!existingPaymentMethod) {
      throw new AppError('Payment method not found', 404);
    }

    // Unset all other default payment methods
    await prisma.userPaymentMethod.updateMany({
      where: { userId, isDefault: true },
      data: { isDefault: false }
    });

    // Set this as default
    const updatedPaymentMethod = await prisma.userPaymentMethod.update({
      where: { id: paymentMethodId },
      data: { isDefault: true }
    });

    logger.info(`💳 ✅ PaymentMethodController: Successfully set payment method ${paymentMethodId} as default`);
    
    res.json({
      status: 'success',
      data: updatedPaymentMethod
    });
  }
} 
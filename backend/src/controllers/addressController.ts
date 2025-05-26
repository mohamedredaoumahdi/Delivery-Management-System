import { Request, Response, NextFunction } from 'express';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { AuthenticatedRequest } from '@/types/express';

export class AddressController {
  getAddresses = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const addresses = await prisma.address.findMany({
      where: { userId: req.user!.id },
    });

    res.json({
      status: 'success',
      data: addresses,
    });
  });

  createAddress = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { label, fullAddress, latitude, longitude, instructions, isDefault } = req.body;

    if (isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user!.id },
        data: { isDefault: false },
      });
    }

    const address = await prisma.address.create({
      data: {
        label,
        fullAddress,
        latitude,
        longitude,
        instructions,
        isDefault,
        userId: req.user!.id,
      },
    });

    res.status(201).json({
      status: 'success',
      data: address,
    });
  });

  updateAddress = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const { label, fullAddress, latitude, longitude, instructions, isDefault } = req.body;

    if (isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user!.id },
        data: { isDefault: false },
      });
    }

    const address = await prisma.address.update({
      where: { id: req.params.id },
      data: {
        label,
        fullAddress,
        latitude,
        longitude,
        instructions,
        isDefault,
      },
    });

    res.json({
      status: 'success',
      data: address,
    });
  });

  deleteAddress = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    await prisma.address.delete({
      where: { id: req.params.id },
    });

    res.json({
      status: 'success',
      data: null,
    });
  });

  setDefaultAddress = catchAsync(async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    await prisma.address.updateMany({
      where: { userId: req.user!.id },
      data: { isDefault: false },
    });

    const address = await prisma.address.update({
      where: { id: req.params.id },
      data: { isDefault: true },
    });

    res.json({
      status: 'success',
      data: address,
    });
  });
} 
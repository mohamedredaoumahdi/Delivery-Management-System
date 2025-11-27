import { Request, Response } from 'express';
import { prisma } from '@/config/database';
import { AppError } from '@/utils/appError';
import { catchAsync } from '@/utils/catchAsync';
import { AuthenticatedRequest } from '@/types/express';
import bcrypt from 'bcrypt';

export class UserController {
  getProfile = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        profilePicture: true,
        role: true,
        vehicleType: true,
        licenseNumber: true,
        isEmailVerified: true,
        isPhoneVerified: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    res.json({ status: 'success', data: user });
  });

  updateProfile = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { name, phone, vehicleType, licenseNumber } = req.body;

    const updateData: any = { name };
    if (phone !== undefined) updateData.phone = phone;
    if (req.user!.role === 'DELIVERY') {
      if (vehicleType !== undefined) updateData.vehicleType = vehicleType;
      if (licenseNumber !== undefined) updateData.licenseNumber = licenseNumber;
    }

    const user = await prisma.user.update({
      where: { id: req.user!.id },
      data: updateData,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        profilePicture: true,
        role: true,
        vehicleType: true,
        licenseNumber: true,
        isEmailVerified: true,
        isPhoneVerified: true,
        isActive: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    res.json({ status: 'success', data: user });
  });

  changePassword = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { currentPassword, newPassword } = req.body;

    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: {
        id: true,
        passwordHash: true,
      },
    });

    if (!user || !(await bcrypt.compare(currentPassword, user.passwordHash))) {
      throw new AppError('Current password is incorrect', 401);
    }

    // Use 12 rounds for password hashing (consistent with registration)
    const hashedPassword = await bcrypt.hash(newPassword, 12);

    await prisma.user.update({
      where: { id: req.user!.id },
      data: { passwordHash: hashedPassword },
    });

    res.json({ status: 'success', message: 'Password updated successfully' });
  });

  getAddresses = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const addresses = await prisma.address.findMany({
      where: { userId: req.user!.id },
      orderBy: { isDefault: 'desc' },
    });

    res.json({ status: 'success', data: addresses });
  });

  addAddress = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
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

    res.status(201).json({ status: 'success', data: address });
  });

  updateAddress = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;
    const { label, fullAddress, latitude, longitude, instructions, isDefault } = req.body;

    if (isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user!.id },
        data: { isDefault: false },
      });
    }

    const address = await prisma.address.update({
      where: { id, userId: req.user!.id },
      data: {
        label,
        fullAddress,
        latitude,
        longitude,
        instructions,
        isDefault,
      },
    });

    res.json({ status: 'success', data: address });
  });

  deleteAddress = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;

    await prisma.address.delete({
      where: { id, userId: req.user!.id },
    });

    res.json({ status: 'success', message: 'Address deleted successfully' });
  });

  setDefaultAddress = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;

    await prisma.address.updateMany({
      where: { userId: req.user!.id },
      data: { isDefault: false },
    });

    const address = await prisma.address.update({
      where: { id, userId: req.user!.id },
      data: { isDefault: true },
    });

    res.json({ status: 'success', data: address });
  });

  getOrderHistory = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const orders = await prisma.order.findMany({
      where: { userId: req.user!.id },
      include: {
        items: {
          include: {
            product: true,
          },
        },
        shop: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ status: 'success', data: orders });
  });

  getOrderDetails = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { id } = req.params;

    const order = await prisma.order.findUnique({
      where: { id, userId: req.user!.id },
      include: {
        items: {
          include: {
            product: true,
          },
        },
        shop: true,
        deliveryPerson: true,
      },
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    res.json({ status: 'success', data: order });
  });

  getFavorites = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const favorites = await prisma.userFavorite.findMany({
      where: { userId: req.user!.id },
      include: { shop: true },
    });

    res.json({ status: 'success', data: favorites });
  });

  addToFavorites = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { shopId } = req.params;

    const favorite = await prisma.userFavorite.create({
      data: {
        userId: req.user!.id,
        shopId,
      },
      include: { shop: true },
    });

    res.status(201).json({ status: 'success', data: favorite });
  });

  removeFromFavorites = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { shopId } = req.params;

    await prisma.userFavorite.delete({
      where: {
        userId_shopId: {
          userId: req.user!.id,
          shopId,
        },
      },
    });

    res.json({ status: 'success', message: 'Removed from favorites' });
  });
} 
import { Response } from 'express';
import { prisma } from '@/config/database';
import { catchAsync } from '@/utils/catchAsync';
import { AuthenticatedRequest } from '@/types/express';

export class DeviceTokenController {
  registerToken = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { token, platform, deviceId } = req.body;

    if (!token) {
      return res.status(400).json({ status: 'error', message: 'token is required' });
    }

    // Upsert by token uniqueness
    const record = await prisma.deviceToken.upsert({
      where: { token },
      update: { userId: req.user!.id, platform, deviceId },
      create: { userId: req.user!.id, token, platform, deviceId },
    });

    return res.status(201).json({ status: 'success', data: record });
  });

  unregisterToken = catchAsync(async (req: AuthenticatedRequest, res: Response) => {
    const { token } = req.params;
    if (!token) {
      return res.status(400).json({ status: 'error', message: 'token is required' });
    }
    await prisma.deviceToken.delete({ where: { token } }).catch(() => undefined);
    return res.json({ status: 'success', message: 'Token unregistered' });
  });
}


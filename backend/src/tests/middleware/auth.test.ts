import { Response, NextFunction } from 'express';
import * as jwt from 'jsonwebtoken';
import { auth } from '@/middleware/auth';
import { AppError } from '@/utils/appError';
import { prisma } from '@/config/database';
import { config } from '@/config/config';
import { AuthenticatedRequest } from '@/types/express';

// Mock dependencies
jest.mock('@/config/database', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
    },
  },
}));

jest.mock('@/config/config', () => ({
  config: {
    jwtSecret: 'test-secret',
  },
}));

describe('Auth Middleware', () => {
  let mockReq: Partial<AuthenticatedRequest>;
  let mockRes: Partial<Response>;
  let nextFunction: NextFunction;

  beforeEach(() => {
    mockReq = {
      header: jest.fn(),
    };
    mockRes = {
      json: jest.fn(),
    };
    nextFunction = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should throw error if no token provided', async () => {
    (mockReq.header as jest.Mock).mockReturnValue(undefined);

    await auth(mockReq as AuthenticatedRequest, mockRes as Response, nextFunction);

    expect(nextFunction).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Access denied. No token provided.',
        statusCode: 401,
      })
    );
  });

  it('should throw error if token is invalid', async () => {
    (mockReq.header as jest.Mock).mockReturnValue('Bearer invalid-token');

    await auth(mockReq as AuthenticatedRequest, mockRes as Response, nextFunction);

    expect(nextFunction).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Token is not valid.',
        statusCode: 401,
      })
    );
  });

  it('should throw error if user not found', async () => {
    const token = jwt.sign({ userId: 'non-existent-id', role: 'USER' }, config.jwtSecret);
    (mockReq.header as jest.Mock).mockReturnValue(`Bearer ${token}`);
    (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);

    await auth(mockReq as AuthenticatedRequest, mockRes as Response, nextFunction);

    expect(nextFunction).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Token is not valid.',
        statusCode: 401,
      })
    );
  });

  it('should throw error if user is inactive', async () => {
    const token = jwt.sign({ userId: 'test-id', role: 'USER' }, config.jwtSecret);
    (mockReq.header as jest.Mock).mockReturnValue(`Bearer ${token}`);
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({
      id: 'test-id',
      email: 'test@example.com',
      name: 'Test User',
      role: 'USER',
      isActive: false,
    });

    await auth(mockReq as AuthenticatedRequest, mockRes as Response, nextFunction);

    expect(nextFunction).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Account has been deactivated.',
        statusCode: 401,
      })
    );
  });

  it('should set user in request and call next if authentication successful', async () => {
    const token = jwt.sign({ userId: 'test-id', role: 'USER' }, config.jwtSecret);
    const mockUser = {
      id: 'test-id',
      email: 'test@example.com',
      name: 'Test User',
      role: 'USER',
      isActive: true,
    };

    (mockReq.header as jest.Mock).mockReturnValue(`Bearer ${token}`);
    (prisma.user.findUnique as jest.Mock).mockResolvedValue(mockUser);

    await auth(mockReq as AuthenticatedRequest, mockRes as Response, nextFunction);

    expect(mockReq.user).toEqual(mockUser);
    expect(nextFunction).toHaveBeenCalledWith();
  });
}); 
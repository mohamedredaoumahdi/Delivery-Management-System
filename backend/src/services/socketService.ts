// src/services/socketService.ts

import { Server } from 'socket.io';
import * as jwt from 'jsonwebtoken';
import { config } from '@/config/config';

/**
 * Initialize Socket.io on an existing server instance.
 * Adds JWT auth middleware and common channel subscriptions.
 */
let ioRef: Server | null = null;

export const getIO = (): Server | null => ioRef;

export const initializeSocket = (io: Server): Server => {
  ioRef = io;
  // Auth middleware: expect token in handshake auth or Authorization header
  io.use((socket, next) => {
    try {
      const authHeader = (socket.handshake.headers['authorization'] || socket.handshake.headers['Authorization']) as string | undefined;
      const tokenFromHeader = authHeader?.startsWith('Bearer ') ? authHeader.substring('Bearer '.length) : undefined;
      const token = (socket.handshake.auth && (socket.handshake.auth as any).token) || tokenFromHeader;

      if (!token) {
        return next(new Error('Unauthorized: missing token'));
      }

      const decoded = jwt.verify(token, config.jwtSecret) as { userId: string; role: string };
      // Stash on socket for later use
      (socket.data as any).userId = decoded.userId;
      (socket.data as any).role = decoded.role;
      return next();
    } catch (err) {
      return next(new Error('Unauthorized: invalid token'));
    }
  });

  io.on('connection', (socket) => {
    // Basic room subscription helpers
    socket.on('subscribe:order', (orderId: string) => {
      if (!orderId) return;
      socket.join(`order:${orderId}`);
    });
    socket.on('unsubscribe:order', (orderId: string) => {
      if (!orderId) return;
      socket.leave(`order:${orderId}`);
    });

    socket.on('subscribe:shop', (shopId: string) => {
      if (!shopId) return;
      socket.join(`shop:${shopId}`);
    });
    socket.on('unsubscribe:shop', (shopId: string) => {
      if (!shopId) return;
      socket.leave(`shop:${shopId}`);
    });

    socket.on('subscribe:user', (userId: string) => {
      if (!userId) return;
      socket.join(`user:${userId}`);
    });
    socket.on('unsubscribe:user', (userId: string) => {
      if (!userId) return;
      socket.leave(`user:${userId}`);
    });

    socket.on('disconnect', () => {
      // Connection closed
    });
  });

  return io;
};
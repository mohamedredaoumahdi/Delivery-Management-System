// src/services/socketService.ts

import { Server } from 'socket.io';
import { Application } from 'express';

export const initializeSocket = (server: any): Server => {
  const io = new Server(server, {
    cors: {
      origin: '*', // @todo: Restrict this to your frontend URL
      methods: ['GET', 'POST']
    }
  });

  io.on('connection', (socket) => {
    console.log('A user connected', socket.id);

    // @todo: Implement your socket event handlers here
    // e.g., socket.on('orderUpdate', (data) => { ... });

    socket.on('disconnect', () => {
      console.log('User disconnected', socket.id);
    });
  });

  console.log('Socket.io initialized');
  return io;
}; 
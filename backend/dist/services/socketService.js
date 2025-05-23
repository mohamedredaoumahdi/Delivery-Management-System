"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.initializeSocket = void 0;
const socket_io_1 = require("socket.io");
const initializeSocket = (server) => {
    const io = new socket_io_1.Server(server, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST']
        }
    });
    io.on('connection', (socket) => {
        console.log('A user connected', socket.id);
        socket.on('disconnect', () => {
            console.log('User disconnected', socket.id);
        });
    });
    console.log('Socket.io initialized');
    return io;
};
exports.initializeSocket = initializeSocket;
//# sourceMappingURL=socketService.js.map
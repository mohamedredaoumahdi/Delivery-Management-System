"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.io = exports.app = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const compression_1 = __importDefault(require("compression"));
const socket_io_1 = require("socket.io");
const http_1 = require("http");
const swagger_ui_express_1 = __importDefault(require("swagger-ui-express"));
const config_1 = require("@/config/config");
const database_1 = require("@/config/database");
const redis_1 = require("@/config/redis");
const errorHandler_1 = require("@/middleware/errorHandler");
const notFoundHandler_1 = require("@/middleware/notFoundHandler");
const rateLimiter_1 = require("@/middleware/rateLimiter");
const logger_1 = require("@/utils/logger");
const routes_1 = __importDefault(require("@/routes"));
const socketService_1 = require("@/services/socketService");
const swagger_1 = require("@/config/swagger");
const app = (0, express_1.default)();
exports.app = app;
const server = (0, http_1.createServer)(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: config_1.config.socketCorsOrigin,
        methods: ['GET', 'POST'],
        credentials: true,
    },
});
exports.io = io;
(0, socketService_1.initializeSocket)(io);
console.log('Socket.io initialized');
app.use((0, helmet_1.default)({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use((0, cors_1.default)({
    origin: config_1.config.corsOrigin,
    credentials: true,
    optionsSuccessStatus: 200,
}));
if (config_1.config.enableCompression) {
    app.use((0, compression_1.default)());
}
if (config_1.config.enableMorganLogging && config_1.config.nodeEnv === 'development') {
    app.use((0, morgan_1.default)('combined'));
}
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true, limit: '10mb' }));
app.use(rateLimiter_1.rateLimiter);
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        environment: config_1.config.nodeEnv,
        version: process.env.npm_package_version || '1.0.0',
    });
});
if (config_1.config.enableSwagger) {
    app.use('/api/docs', swagger_ui_express_1.default.serve, swagger_ui_express_1.default.setup(swagger_1.swaggerSpec));
}
app.use('/api', routes_1.default);
app.use('/uploads', express_1.default.static(config_1.config.uploadDir));
app.use(notFoundHandler_1.notFoundHandler);
app.use(errorHandler_1.errorHandler);
const gracefulShutdown = async (signal) => {
    logger_1.logger.info(`Received ${signal}. Starting graceful shutdown...`);
    try {
        await (0, redis_1.disconnectRedis)();
        logger_1.logger.info('Redis connection closed');
    }
    catch (error) {
        logger_1.logger.error('Error closing Redis connection:', error);
    }
    server.close(() => {
        logger_1.logger.info('HTTP server closed');
        process.exit(0);
    });
    setTimeout(() => {
        logger_1.logger.error('Could not close connections in time, forcefully shutting down');
        process.exit(1);
    }, 30000);
};
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGUSR2', () => gracefulShutdown('SIGUSR2'));
process.on('unhandledRejection', (reason, promise) => {
    logger_1.logger.error('Unhandled Rejection at:', reason);
});
process.on('uncaughtException', (error) => {
    logger_1.logger.error('Uncaught Exception:', error);
    process.exit(1);
});
const startServer = async () => {
    try {
        await (0, database_1.connectDatabase)();
        logger_1.logger.info('Database connected successfully');
        await (0, redis_1.connectRedis)();
        server.listen(config_1.config.port, () => {
            logger_1.logger.info(`Server running on port ${config_1.config.port} in ${config_1.config.nodeEnv} mode`);
            if (config_1.config.enableSwagger) {
                logger_1.logger.info(`API Documentation available at http://localhost:${config_1.config.port}/api/docs`);
            }
        });
    }
    catch (error) {
        logger_1.logger.error('Failed to start server:', error);
        process.exit(1);
    }
};
startServer();
//# sourceMappingURL=index.js.map
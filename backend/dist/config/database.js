"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runTransaction = exports.checkDatabaseHealth = exports.disconnectDatabase = exports.connectDatabase = exports.prisma = void 0;
const client_1 = require("@prisma/client");
const config_1 = require("./config");
const logger_1 = require("@/utils/logger");
const createPrismaClient = () => {
    return new client_1.PrismaClient({
        datasources: {
            db: {
                url: config_1.config.databaseUrl,
            },
        },
        log: config_1.config.nodeEnv === 'development'
            ? ['query', 'info', 'warn', 'error']
            : ['error'],
        errorFormat: 'minimal',
    });
};
exports.prisma = globalThis.__prisma || createPrismaClient();
if (config_1.config.nodeEnv === 'development') {
    globalThis.__prisma = exports.prisma;
}
const connectDatabase = async () => {
    try {
        await exports.prisma.$connect();
        logger_1.logger.info('Database connection established successfully');
        await exports.prisma.$queryRaw `SELECT 1`;
        logger_1.logger.info('Database connection test passed');
    }
    catch (error) {
        logger_1.logger.error('Database connection failed:', error);
        throw error;
    }
};
exports.connectDatabase = connectDatabase;
const disconnectDatabase = async () => {
    try {
        await exports.prisma.$disconnect();
        logger_1.logger.info('Database disconnected successfully');
    }
    catch (error) {
        logger_1.logger.error('Database disconnection failed:', error);
        throw error;
    }
};
exports.disconnectDatabase = disconnectDatabase;
const checkDatabaseHealth = async () => {
    try {
        await exports.prisma.$queryRaw `SELECT 1`;
        return true;
    }
    catch (error) {
        logger_1.logger.error('Database health check failed:', error);
        return false;
    }
};
exports.checkDatabaseHealth = checkDatabaseHealth;
const runTransaction = async (callback) => {
    return await exports.prisma.$transaction(callback);
};
exports.runTransaction = runTransaction;
process.on('beforeExit', async () => {
    await (0, exports.disconnectDatabase)();
});
exports.prisma.$on('error', (e) => {
    logger_1.logger.error('Prisma error:', e);
});
if (config_1.config.nodeEnv === 'development') {
    exports.prisma.$on('query', (e) => {
        logger_1.logger.debug(`Query: ${e.query}`);
        logger_1.logger.debug(`Duration: ${e.duration}ms`);
    });
}
exports.default = exports.prisma;
//# sourceMappingURL=database.js.map
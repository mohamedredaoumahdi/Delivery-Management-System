"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SessionService = exports.CacheService = exports.checkRedisHealth = exports.getRedisClient = exports.disconnectRedis = exports.connectRedis = void 0;
const ioredis_1 = __importDefault(require("ioredis"));
const config_1 = require("./config");
const logger_1 = require("@/utils/logger");
let redisClient = null;
const createRedisClient = () => {
    const redis = new ioredis_1.default(config_1.config.redisUrl);
    redis.on('connect', () => {
        logger_1.logger.info('Redis client connected');
    });
    redis.on('ready', () => {
        logger_1.logger.info('Redis client ready');
    });
    redis.on('error', (error) => {
        logger_1.logger.error('Redis client error:', error);
    });
    redis.on('close', () => {
        logger_1.logger.warn('Redis client connection closed');
    });
    redis.on('reconnecting', () => {
        logger_1.logger.info('Redis client reconnecting');
    });
    redis.on('end', () => {
        logger_1.logger.info('Redis client connection ended');
    });
    return redis;
};
const connectRedis = async () => {
    try {
        if (redisClient && redisClient.status === 'ready') {
            logger_1.logger.info('Redis already connected');
            return;
        }
        if (redisClient && redisClient.status !== 'end') {
            logger_1.logger.info('Disconnecting existing Redis client');
            redisClient.disconnect();
            redisClient = null;
        }
        redisClient = createRedisClient();
        await new Promise((resolve, reject) => {
            if (!redisClient) {
                reject(new Error('Redis client not initialized'));
                return;
            }
            if (redisClient.status === 'ready') {
                resolve();
                return;
            }
            const onReady = () => {
                redisClient.off('error', onError);
                resolve();
            };
            const onError = (error) => {
                redisClient.off('ready', onReady);
                reject(error);
            };
            redisClient.once('ready', onReady);
            redisClient.once('error', onError);
        });
        logger_1.logger.info('Redis connected successfully');
    }
    catch (error) {
        logger_1.logger.error('Redis connection failed:', error);
        throw error;
    }
};
exports.connectRedis = connectRedis;
const disconnectRedis = async () => {
    try {
        if (redisClient) {
            await redisClient.quit();
            redisClient = null;
            logger_1.logger.info('Redis disconnected successfully');
        }
    }
    catch (error) {
        logger_1.logger.error('Redis disconnection failed:', error);
        throw error;
    }
};
exports.disconnectRedis = disconnectRedis;
const getRedisClient = () => {
    if (!redisClient) {
        throw new Error('Redis client not initialized. Call connectRedis() first.');
    }
    return redisClient;
};
exports.getRedisClient = getRedisClient;
const checkRedisHealth = async () => {
    try {
        if (!redisClient) {
            return false;
        }
        const result = await redisClient.ping();
        return result === 'PONG';
    }
    catch (error) {
        logger_1.logger.error('Redis health check failed:', error);
        return false;
    }
};
exports.checkRedisHealth = checkRedisHealth;
class CacheService {
    static redis = () => (0, exports.getRedisClient)();
    static async set(key, value, ttl) {
        const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
        if (ttl) {
            await this.redis().setex(key, ttl, stringValue);
        }
        else {
            await this.redis().set(key, stringValue);
        }
    }
    static async get(key) {
        const value = await this.redis().get(key);
        if (!value) {
            return null;
        }
        try {
            return JSON.parse(value);
        }
        catch {
            return value;
        }
    }
    static async del(key) {
        await this.redis().del(key);
    }
    static async exists(key) {
        const result = await this.redis().exists(key);
        return result === 1;
    }
    static async expire(key, seconds) {
        await this.redis().expire(key, seconds);
    }
    static async ttl(key) {
        return await this.redis().ttl(key);
    }
    static async incr(key) {
        return await this.redis().incr(key);
    }
    static async mset(keyValuePairs) {
        const flatArray = [];
        for (const [key, value] of Object.entries(keyValuePairs)) {
            flatArray.push(key);
            flatArray.push(typeof value === 'string' ? value : JSON.stringify(value));
        }
        await this.redis().mset(...flatArray);
    }
    static async mget(keys) {
        const values = await this.redis().mget(...keys);
        return values.map(value => {
            if (!value)
                return null;
            try {
                return JSON.parse(value);
            }
            catch {
                return value;
            }
        });
    }
    static async clear() {
        await this.redis().flushdb();
    }
    static async keys(pattern) {
        return await this.redis().keys(pattern);
    }
}
exports.CacheService = CacheService;
class SessionService {
    static SESSION_PREFIX = 'session:';
    static REFRESH_TOKEN_PREFIX = 'refresh:';
    static async setSession(userId, sessionData, ttl = 3600) {
        const key = `${this.SESSION_PREFIX}${userId}`;
        await CacheService.set(key, sessionData, ttl);
    }
    static async getSession(userId) {
        const key = `${this.SESSION_PREFIX}${userId}`;
        return await CacheService.get(key);
    }
    static async deleteSession(userId) {
        const key = `${this.SESSION_PREFIX}${userId}`;
        await CacheService.del(key);
    }
    static async setRefreshToken(tokenId, userId, ttl = 604800) {
        const key = `${this.REFRESH_TOKEN_PREFIX}${tokenId}`;
        await CacheService.set(key, { userId }, ttl);
    }
    static async getRefreshToken(tokenId) {
        const key = `${this.REFRESH_TOKEN_PREFIX}${tokenId}`;
        return await CacheService.get(key);
    }
    static async deleteRefreshToken(tokenId) {
        const key = `${this.REFRESH_TOKEN_PREFIX}${tokenId}`;
        await CacheService.del(key);
    }
}
exports.SessionService = SessionService;
process.on('beforeExit', async () => {
    await (0, exports.disconnectRedis)();
});
exports.default = redisClient;
//# sourceMappingURL=redis.js.map
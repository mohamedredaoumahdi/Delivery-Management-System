// src/config/redis.ts
import Redis from 'ioredis';
import { config } from './config';
import { logger } from '@/utils/logger';

// Redis client instance
let redisClient: Redis | null = null;

// Create Redis client
const createRedisClient = (): Redis => {
  const redis = new Redis(config.redisUrl);

  // Redis event handlers
  redis.on('connect', () => {
    logger.info('Redis client connected');
  });

  redis.on('ready', () => {
    logger.info('Redis client ready');
  });

  redis.on('error', (error) => {
    logger.error('Redis client error:', error);
  });

  redis.on('close', () => {
    logger.warn('Redis client connection closed');
  });

  redis.on('reconnecting', () => {
    logger.info('Redis client reconnecting');
  });

  redis.on('end', () => {
    logger.info('Redis client connection ended');
  });

  return redis;
};

// Connect to Redis
export const connectRedis = async (): Promise<void> => {
  try {
    // If client already exists and is ready, return early
    if (redisClient && redisClient.status === 'ready') {
      logger.info('Redis already connected');
      return;
    }

    // If client exists but not ready, disconnect first
    if (redisClient && redisClient.status !== 'end') {
      logger.info('Disconnecting existing Redis client');
      redisClient.disconnect();
      redisClient = null;
    }

    // Create new Redis client (it will auto-connect)
    redisClient = createRedisClient();
    
    // Wait for the connection to be ready
    await new Promise<void>((resolve, reject) => {
      if (!redisClient) {
        reject(new Error('Redis client not initialized'));
        return;
      }

      if (redisClient.status === 'ready') {
        resolve();
        return;
      }

      const onReady = () => {
        redisClient!.off('error', onError);
        resolve();
      };

      const onError = (error: Error) => {
        redisClient!.off('ready', onReady);
        reject(error);
      };

      redisClient.once('ready', onReady);
      redisClient.once('error', onError);
    });

    logger.info('Redis connected successfully');
  } catch (error) {
    logger.error('Redis connection failed:', error);
    throw error;
  }
};

// Disconnect from Redis
export const disconnectRedis = async (): Promise<void> => {
  try {
    if (redisClient) {
      await redisClient.quit();
      redisClient = null;
      logger.info('Redis disconnected successfully');
    }
  } catch (error) {
    logger.error('Redis disconnection failed:', error);
    throw error;
  }
};

// Get Redis client instance
export const getRedisClient = (): Redis => {
  if (!redisClient) {
    throw new Error('Redis client not initialized. Call connectRedis() first.');
  }
  return redisClient;
};

// Redis health check
export const checkRedisHealth = async (): Promise<boolean> => {
  try {
    if (!redisClient) {
      return false;
    }
    const result = await redisClient.ping();
    return result === 'PONG';
  } catch (error) {
    logger.error('Redis health check failed:', error);
    return false;
  }
};

// Cache helper functions
export class CacheService {
  private static redis = () => getRedisClient();

  // Set a value with optional expiration (in seconds)
  static async set(key: string, value: any, ttl?: number): Promise<void> {
    const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
    
    if (ttl) {
      await this.redis().setex(key, ttl, stringValue);
    } else {
      await this.redis().set(key, stringValue);
    }
  }

  // Get a value
  static async get<T = any>(key: string): Promise<T | null> {
    const value = await this.redis().get(key);
    
    if (!value) {
      return null;
    }
    
    try {
      return JSON.parse(value) as T;
    } catch {
      return value as T;
    }
  }

  // Delete a key
  static async del(key: string): Promise<void> {
    await this.redis().del(key);
  }

  // Check if key exists
  static async exists(key: string): Promise<boolean> {
    const result = await this.redis().exists(key);
    return result === 1;
  }

  // Set expiration for a key
  static async expire(key: string, seconds: number): Promise<void> {
    await this.redis().expire(key, seconds);
  }

  // Get TTL for a key
  static async ttl(key: string): Promise<number> {
    return await this.redis().ttl(key);
  }

  // Increment a value
  static async incr(key: string): Promise<number> {
    return await this.redis().incr(key);
  }

  // Set multiple values
  static async mset(keyValuePairs: Record<string, any>): Promise<void> {
    const flatArray: string[] = [];
    
    for (const [key, value] of Object.entries(keyValuePairs)) {
      flatArray.push(key);
      flatArray.push(typeof value === 'string' ? value : JSON.stringify(value));
    }
    
    await this.redis().mset(...flatArray);
  }

  // Get multiple values
  static async mget<T = any>(keys: string[]): Promise<(T | null)[]> {
    const values = await this.redis().mget(...keys);
    
    return values.map(value => {
      if (!value) return null;
      
      try {
        return JSON.parse(value) as T;
      } catch {
        return value as T;
      }
    });
  }

  // Clear all cache (use with caution)
  static async clear(): Promise<void> {
    await this.redis().flushdb();
  }

  // Get all keys matching a pattern
  static async keys(pattern: string): Promise<string[]> {
    return await this.redis().keys(pattern);
  }
}

// Session management helpers
export class SessionService {
  private static readonly SESSION_PREFIX = 'session:';
  private static readonly REFRESH_TOKEN_PREFIX = 'refresh:';

  // Set user session
  static async setSession(userId: string, sessionData: any, ttl: number = 3600): Promise<void> {
    const key = `${this.SESSION_PREFIX}${userId}`;
    await CacheService.set(key, sessionData, ttl);
  }

  // Get user session
  static async getSession<T = any>(userId: string): Promise<T | null> {
    const key = `${this.SESSION_PREFIX}${userId}`;
    return await CacheService.get<T>(key);
  }

  // Delete user session
  static async deleteSession(userId: string): Promise<void> {
    const key = `${this.SESSION_PREFIX}${userId}`;
    await CacheService.del(key);
  }

  // Set refresh token
  static async setRefreshToken(tokenId: string, userId: string, ttl: number = 604800): Promise<void> {
    const key = `${this.REFRESH_TOKEN_PREFIX}${tokenId}`;
    await CacheService.set(key, { userId }, ttl);
  }

  // Get refresh token data
  static async getRefreshToken(tokenId: string): Promise<{ userId: string } | null> {
    const key = `${this.REFRESH_TOKEN_PREFIX}${tokenId}`;
    return await CacheService.get(key);
  }

  // Delete refresh token
  static async deleteRefreshToken(tokenId: string): Promise<void> {
    const key = `${this.REFRESH_TOKEN_PREFIX}${tokenId}`;
    await CacheService.del(key);
  }
}

// Graceful shutdown handler
process.on('beforeExit', async () => {
  await disconnectRedis();
});

export default redisClient;
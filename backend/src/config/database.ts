// src/config/database.ts
import { PrismaClient } from '@prisma/client';
import { config } from './config';
import { logger } from '@/utils/logger';

// Global Prisma client instance
declare global {
  var __prisma: PrismaClient | undefined;
}

// Create Prisma client with configuration
const createPrismaClient = (): PrismaClient => {
  return new PrismaClient({
    datasources: {
      db: {
        url: config.databaseUrl,
      },
    },
    log: config.nodeEnv === 'development' 
      ? ['query', 'info', 'warn', 'error'] 
      : ['error'],
    errorFormat: 'minimal',
  });
};

// Use global instance in development to prevent multiple connections
export const prisma = globalThis.__prisma || createPrismaClient();

if (config.nodeEnv === 'development') {
  globalThis.__prisma = prisma;
}

// Database connection function
export const connectDatabase = async (): Promise<void> => {
  try {
    await prisma.$connect();
    logger.info('Database connection established successfully');
    
    // Test the connection
    await prisma.$queryRaw`SELECT 1`;
    logger.info('Database connection test passed');
    
  } catch (error) {
    logger.error('Database connection failed:', error);
    throw error;
  }
};

// Database disconnection function
export const disconnectDatabase = async (): Promise<void> => {
  try {
    await prisma.$disconnect();
    logger.info('Database disconnected successfully');
  } catch (error) {
    logger.error('Database disconnection failed:', error);
    throw error;
  }
};

// Database health check
export const checkDatabaseHealth = async (): Promise<boolean> => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return true;
  } catch (error) {
    logger.error('Database health check failed:', error);
    return false;
  }
};

// Database transaction helper
// Define a type for the transaction client
type TransactionClient = Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>;

export const runTransaction = async <T>(
  callback: (tx: TransactionClient) => Promise<T> // Use the defined TransactionClient type
): Promise<T> => {
  return await prisma.$transaction(callback);
};

// Graceful shutdown handler
process.on('beforeExit', async () => {
  await disconnectDatabase();
});

// Handle specific database errors
prisma.$on('error' as never, (e: any) => {
  logger.error('Prisma error:', e);
});

// Performance monitoring (development only)
if (config.nodeEnv === 'development') {
  prisma.$on('query' as never, (e: any) => {
    logger.debug(`Query: ${e.query}`);
    logger.debug(`Duration: ${e.duration}ms`);
  });
}

export default prisma;
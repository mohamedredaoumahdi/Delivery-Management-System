// Test setup file
import { config } from '@/config/config';

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret';

// Use test database if specified, otherwise use main database (tests will clean up)
// For now, use the main database - tests will clean up after themselves
if (!process.env.TEST_DATABASE_URL) {
  // Use main database URL but tests should clean up their data
  process.env.DATABASE_URL = process.env.DATABASE_URL || 'postgresql://admin:admin123@localhost:5432/delivery_system';
}

// Increase timeout for tests
jest.setTimeout(30000);

// Global test utilities
global.console = {
  ...console,
  // Uncomment to silence console logs during tests
  // log: jest.fn(),
  // debug: jest.fn(),
  // info: jest.fn(),
  // warn: jest.fn(),
  // error: jest.fn(),
};

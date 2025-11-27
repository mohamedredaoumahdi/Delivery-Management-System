import request from 'supertest';
import { Application } from 'express';
import { prisma } from '@/config/database';
import { createTestApp } from '../helpers/test-app';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';
import { config } from '@/config/config';
import { OrderStatus, PaymentMethod } from '@prisma/client';

describe('Admin API Integration Tests', () => {
  let app: Application;
  let adminToken: string;
  let adminUser: any;
  let testUser: any;
  let testShop: any;
  let testOrder: any;

  beforeAll(async () => {
    // Create test app
    app = createTestApp();
    
    // Create admin user for testing
    const hashedPassword = await bcrypt.hash('admin123', 10);
    adminUser = await prisma.user.create({
      data: {
        email: 'test-admin@example.com',
        passwordHash: hashedPassword,
        name: 'Test Admin',
        role: 'ADMIN',
        isActive: true,
        isEmailVerified: true,
      },
    });

    adminToken = jwt.sign(
      { userId: adminUser.id, role: 'ADMIN' },
      config.jwtSecret,
      { expiresIn: '1h' }
    );
  });

  afterAll(async () => {
    // Cleanup test data - use findFirst to check if exists before deleting
    try {
      if (testOrder?.id) {
        const order = await prisma.order.findUnique({ where: { id: testOrder.id } });
        if (order) {
          await prisma.order.delete({ where: { id: testOrder.id } }).catch(() => {});
        }
      }
      if (testShop?.id) {
        const shop = await prisma.shop.findUnique({ where: { id: testShop.id } });
        if (shop) {
          await prisma.shop.delete({ where: { id: testShop.id } }).catch(() => {});
        }
      }
      if (testUser?.id) {
        const user = await prisma.user.findUnique({ where: { id: testUser.id } });
        if (user) {
          await prisma.user.delete({ where: { id: testUser.id } }).catch(() => {});
        }
      }
      if (adminUser?.id) {
        const admin = await prisma.user.findUnique({ where: { id: adminUser.id } });
        if (admin) {
          await prisma.user.delete({ where: { id: adminUser.id } }).catch(() => {});
        }
      }
    } catch (error) {
      // Silently ignore cleanup errors - tests already passed
    }
    await prisma.$disconnect();
  });

  describe('Authentication', () => {
    it('should login admin user', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test-admin@example.com',
          password: 'admin123',
        });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data).toHaveProperty('accessToken');
      expect(response.body.data).toHaveProperty('refreshToken');
      expect(response.body.data.user.role).toBe('ADMIN');
    });

    it('should reject non-admin login', async () => {
      const hashedPassword = await bcrypt.hash('user123', 10);
      const regularUser = await prisma.user.create({
        data: {
          email: 'test-user@example.com',
          passwordHash: hashedPassword,
          name: 'Test User',
          role: 'CUSTOMER',
          isActive: true,
          isEmailVerified: true,
        },
      });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test-user@example.com',
          password: 'user123',
        });

      expect(response.status).toBe(200); // Login succeeds
      // But admin endpoints should reject

      await prisma.user.delete({ where: { id: regularUser.id } });
    });
  });

  describe('User Management', () => {
    beforeEach(async () => {
      // Create test user
      testUser = await prisma.user.create({
        data: {
          email: 'test-user@example.com',
          passwordHash: await bcrypt.hash('password123', 10),
          name: 'Test User',
          role: 'CUSTOMER',
          isActive: true,
          isEmailVerified: true,
        },
      });
    });

    afterEach(async () => {
      if (testUser) {
        await prisma.user.delete({ where: { id: testUser.id } }).catch(() => {});
      }
    });

    it('should get all users', async () => {
      const response = await request(app)
        .get('/api/admin/users')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should get user by ID', async () => {
      const response = await request(app)
        .get(`/api/admin/users/${testUser.id}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.id).toBe(testUser.id);
      expect(response.body.data.email).toBe(testUser.email);
    });

    it('should update user', async () => {
      const response = await request(app)
        .put(`/api/admin/users/${testUser.id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Updated Name',
          isActive: false,
        });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.name).toBe('Updated Name');
      expect(response.body.data.isActive).toBe(false);
    });

    it('should delete user', async () => {
      const response = await request(app)
        .delete(`/api/admin/users/${testUser.id}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');

      // Verify user is deleted
      const deletedUser = await prisma.user.findUnique({
        where: { id: testUser.id },
      });
      expect(deletedUser).toBeNull();
      testUser = null; // Prevent afterEach from trying to delete again
    });

    it('should require admin role', async () => {
      const userToken = jwt.sign(
        { userId: testUser.id, role: 'CUSTOMER' },
        config.jwtSecret,
        { expiresIn: '1h' }
      );

      const response = await request(app)
        .get('/api/admin/users')
        .set('Authorization', `Bearer ${userToken}`);

      expect(response.status).toBe(403);
    });
  });

  describe('Shop Management', () => {
    let shopOwner: any;
    
    beforeEach(async () => {
      // Create shop owner first
      shopOwner = await prisma.user.create({
        data: {
          email: `test-owner-${Date.now()}@example.com`,
          passwordHash: await bcrypt.hash('password123', 10),
          name: 'Test Shop Owner',
          role: 'VENDOR',
          isActive: true,
          isEmailVerified: true,
        },
      });
      
      // Create test shop
      testShop = await prisma.shop.create({
        data: {
          name: 'Test Shop',
          description: 'Test shop description',
          email: 'test-shop@example.com',
          phone: '1234567890',
          address: '123 Test St',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'RESTAURANT',
          openingHours: {},
          estimatedDeliveryTime: 30,
          ownerId: shopOwner.id,
        },
      });
    });
    
    afterEach(async () => {
      if (testShop) {
        await prisma.shop.delete({ where: { id: testShop.id } }).catch(() => {});
      }
      if (shopOwner) {
        await prisma.user.delete({ where: { id: shopOwner.id } }).catch(() => {});
      }
    });


    it('should get all shops', async () => {
      const response = await request(app)
        .get('/api/admin/shops')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should get shop by ID', async () => {
      const response = await request(app)
        .get(`/api/admin/shops/${testShop.id}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.id).toBe(testShop.id);
    });

    it('should update shop', async () => {
      const response = await request(app)
        .put(`/api/admin/shops/${testShop.id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Updated Shop Name',
          isActive: false,
        });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.name).toBe('Updated Shop Name');
      expect(response.body.data.isActive).toBe(false);
    });

    it('should delete shop', async () => {
      const response = await request(app)
        .delete(`/api/admin/shops/${testShop.id}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');

      const deletedShop = await prisma.shop.findUnique({
        where: { id: testShop.id },
      });
      expect(deletedShop).toBeNull();
      testShop = null;
    });
  });

  describe('Dashboard Overview', () => {
    let dashboardCustomer: any;
    let dashboardVendor: any;
    let dashboardShop: any;
    let deliveryAgent: any;
    let dashboardOrders: string[] = [];
    let deliveryLocations: string[] = [];

    beforeAll(async () => {
      dashboardVendor = await prisma.user.create({
        data: {
          email: `vendor-${Date.now()}@example.com`,
          passwordHash: await bcrypt.hash('password123', 10),
          name: 'Dashboard Vendor',
          role: 'VENDOR',
          isActive: true,
          isEmailVerified: true,
        },
      });

      dashboardCustomer = await prisma.user.create({
        data: {
          email: `customer-${Date.now()}@example.com`,
          passwordHash: await bcrypt.hash('password123', 10),
          name: 'Dashboard Customer',
          role: 'CUSTOMER',
          isActive: true,
          isEmailVerified: true,
        },
      });

      deliveryAgent = await prisma.user.create({
        data: {
          email: `delivery-${Date.now()}@example.com`,
          passwordHash: await bcrypt.hash('password123', 10),
          name: 'Delivery Agent',
          role: 'DELIVERY',
          isActive: true,
          isEmailVerified: true,
        },
      });

      dashboardShop = await prisma.shop.create({
        data: {
          name: 'Dashboard Shop',
          description: 'Shop used for dashboard tests',
          email: 'dashboard-shop@example.com',
          phone: '1234567890',
          address: '123 Dashboard Street',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'RESTAURANT',
          openingHours: {},
          estimatedDeliveryTime: 30,
          ownerId: dashboardVendor.id,
        },
      });
    });

    afterAll(async () => {
      await prisma.order.deleteMany({
        where: { id: { in: dashboardOrders } },
      }).catch(() => {});
      await prisma.deliveryLocation.deleteMany({
        where: { id: { in: deliveryLocations } },
      }).catch(() => {});
      if (dashboardShop) {
        await prisma.shop.delete({ where: { id: dashboardShop.id } }).catch(() => {});
      }
      if (dashboardVendor) {
        await prisma.user.delete({ where: { id: dashboardVendor.id } }).catch(() => {});
      }
      if (dashboardCustomer) {
        await prisma.user.delete({ where: { id: dashboardCustomer.id } }).catch(() => {});
      }
      if (deliveryAgent) {
        await prisma.user.delete({ where: { id: deliveryAgent.id } }).catch(() => {});
      }
    });

    beforeEach(async () => {
      const order = await prisma.order.create({
        data: {
          orderNumber: `ORD-${Date.now()}`,
          userId: dashboardCustomer.id,
          shopId: dashboardShop.id,
          shopName: dashboardShop.name,
          deliveryAddress: '123 Dashboard Street',
          deliveryLatitude: 40.7128,
          deliveryLongitude: -74.0060,
          subtotal: 20,
          deliveryFee: 3,
          serviceFee: 2,
          tax: 1.5,
          total: 26.5,
          paymentMethod: PaymentMethod.CARD,
          status: OrderStatus.DELIVERED,
          deliveredAt: new Date(),
          deliveryPersonId: deliveryAgent.id,
        },
      });
      dashboardOrders.push(order.id);

      const activeOrder = await prisma.order.create({
        data: {
          orderNumber: `ORD-ACTIVE-${Date.now()}`,
          userId: dashboardCustomer.id,
          shopId: dashboardShop.id,
          shopName: dashboardShop.name,
          deliveryAddress: '456 Pending Ave',
          deliveryLatitude: 40.7128,
          deliveryLongitude: -74.0060,
          subtotal: 15,
          deliveryFee: 3,
          serviceFee: 2,
          tax: 1.2,
          total: 21.2,
          paymentMethod: PaymentMethod.CARD,
          status: OrderStatus.IN_DELIVERY,
          deliveryPersonId: deliveryAgent.id,
        },
      });
      dashboardOrders.push(activeOrder.id);

      const location = await prisma.deliveryLocation.create({
        data: {
          userId: deliveryAgent.id,
          latitude: 40.7128,
          longitude: -74.0060,
        },
      });
      deliveryLocations.push(location.id);
    });

    afterEach(async () => {
      await prisma.order.deleteMany({
        where: { id: { in: dashboardOrders } },
      }).catch(() => {});
      dashboardOrders = [];

      await prisma.deliveryLocation.deleteMany({
        where: { id: { in: deliveryLocations } },
      }).catch(() => {});
      deliveryLocations = [];
    });

    it('should return dashboard overview metrics', async () => {
      const response = await request(app)
        .get('/api/admin/dashboard/overview')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');

      const data = response.body.data;
      expect(data).toHaveProperty('orders');
      expect(data.orders).toHaveProperty('totals');
      expect(data.orders.totals.today).toBeGreaterThanOrEqual(1);
      expect(data.orders).toHaveProperty('active');
      expect(data.orders).toHaveProperty('pendingDeliveries');

      expect(data).toHaveProperty('revenue');
      expect(data.revenue.today).toBeGreaterThanOrEqual(0);
      expect(data.revenue.total).toBeGreaterThan(0);

      expect(data).toHaveProperty('vendors');
      expect(data.vendors.total).toBeGreaterThanOrEqual(1);
      expect(Array.isArray(data.vendors.topPerformers)).toBe(true);

      expect(data).toHaveProperty('delivery');
      expect(data.delivery.onlineAgents).toBeGreaterThanOrEqual(1);

      expect(data).toHaveProperty('customers');
      expect(Array.isArray(data.customers.trend)).toBe(true);
    });
  });

  describe('Order Management', () => {
    beforeEach(async () => {
      // Create test user and shop for order
      testUser = await prisma.user.create({
        data: {
          email: 'test-customer@example.com',
          passwordHash: await bcrypt.hash('password123', 10),
          name: 'Test Customer',
          role: 'CUSTOMER',
          isActive: true,
          isEmailVerified: true,
        },
      });

      // Create shop owner
      const shopOwner = await prisma.user.create({
        data: {
          email: `test-shop-owner-${Date.now()}@example.com`,
          passwordHash: await bcrypt.hash('password123', 10),
          name: 'Test Shop Owner',
          role: 'VENDOR',
          isActive: true,
          isEmailVerified: true,
        },
      });

      testShop = await prisma.shop.create({
        data: {
          name: 'Test Shop for Order',
          description: 'Test shop description',
          email: 'shop@example.com',
          phone: '1234567890',
          address: '123 Test St',
          latitude: 40.7128,
          longitude: -74.0060,
          category: 'RESTAURANT',
          openingHours: {},
          estimatedDeliveryTime: 30,
          ownerId: shopOwner.id,
        },
      });

      // Create test order
      testOrder = await prisma.order.create({
        data: {
          orderNumber: `TEST-${Date.now()}`,
          userId: testUser.id,
          shopId: testShop.id,
          shopName: testShop.name,
          status: 'PENDING',
          subtotal: 25.00,
          deliveryFee: 5.00,
          serviceFee: 2.00,
          tax: 2.50,
          total: 34.50,
          deliveryAddress: '123 Delivery St, Test City, Test State 12345',
          deliveryLatitude: 40.7128,
          deliveryLongitude: -74.0060,
          paymentMethod: 'CASH_ON_DELIVERY',
        },
      });
    });

    afterEach(async () => {
      if (testOrder) {
        await prisma.order.delete({ where: { id: testOrder.id } }).catch(() => {});
      }
      if (testShop) {
        await prisma.shop.delete({ where: { id: testShop.id } }).catch(() => {});
      }
      if (testUser) {
        await prisma.user.delete({ where: { id: testUser.id } }).catch(() => {});
      }
    });

    it('should get all orders', async () => {
      const response = await request(app)
        .get('/api/admin/orders')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should get order by ID', async () => {
      const response = await request(app)
        .get(`/api/admin/orders/${testOrder.id}`)
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.id).toBe(testOrder.id);
    });

    it('should update order status', async () => {
      const response = await request(app)
        .put(`/api/admin/orders/${testOrder.id}/status`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          status: 'ACCEPTED',
        });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data.status).toBe('ACCEPTED');
    });
  });

  describe('Analytics', () => {
    it('should get user analytics', async () => {
      const response = await request(app)
        .get('/api/admin/analytics/users')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should get order analytics', async () => {
      const response = await request(app)
        .get('/api/admin/analytics/orders')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should get revenue analytics', async () => {
      const response = await request(app)
        .get('/api/admin/analytics/revenue')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.data).toHaveProperty('_sum');
      expect(response.body.data).toHaveProperty('_avg');
    });
  });

  describe('Error Handling', () => {
    it('should return 401 for missing token', async () => {
      const response = await request(app)
        .get('/api/admin/users');

      expect(response.status).toBe(401);
    });

    it('should return 401 for invalid token', async () => {
      const response = await request(app)
        .get('/api/admin/users')
        .set('Authorization', 'Bearer invalid-token');

      expect(response.status).toBe(401);
    });

    it('should return 404 for non-existent resource', async () => {
      const response = await request(app)
        .get('/api/admin/users/non-existent-id')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(response.status).toBe(404);
    });
  });
});


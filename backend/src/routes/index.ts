// src/routes/index.ts
import { Express } from 'express';
import authRoutes from './auth';
import userRoutes from './users';
import shopRoutes from './shops';
import productRoutes from './products';
import orderRoutes from './orders';
import addressRoutes from './addresses';
import reviewRoutes from './reviews';
import vendorRoutes from './vendor';
import deliveryRoutes from './delivery';
import adminRoutes from './admin';

export const setupRoutes = (app: Express): void => {
  // API version prefix
  const apiPrefix = '/api/v1';

  // Health check (outside API versioning)
  app.get('/api/health', (req, res) => {
    res.json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    });
  });

  // Public routes
  app.use(`${apiPrefix}/auth`, authRoutes);
  app.use(`${apiPrefix}/shops`, shopRoutes);
  app.use(`${apiPrefix}/products`, productRoutes);

  // Protected routes (require authentication)
  app.use(`${apiPrefix}/users`, userRoutes);
  app.use(`${apiPrefix}/orders`, orderRoutes);
  app.use(`${apiPrefix}/addresses`, addressRoutes);
  app.use(`${apiPrefix}/reviews`, reviewRoutes);

  // Role-specific routes
  app.use(`${apiPrefix}/vendor`, vendorRoutes);
  app.use(`${apiPrefix}/delivery`, deliveryRoutes);
  app.use(`${apiPrefix}/admin`, adminRoutes);
};

// src/routes/auth.ts
import { Router } from 'express';
import { AuthController } from '@/controllers/authController';
import { validateRequest } from '@/middleware/validation';
import { loginSchema, registerSchema, refreshTokenSchema } from '@/validators/authValidators';
import { rateLimiter } from '@/middleware/rateLimiter';

const router = Router();
const authController = new AuthController();

// Apply rate limiting to auth routes
router.use(rateLimiter);

router.post('/register', validateRequest(registerSchema), authController.register);
router.post('/login', validateRequest(loginSchema), authController.login);
router.post('/refresh', validateRequest(refreshTokenSchema), authController.refreshToken);
router.post('/logout', authController.logout);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.post('/verify-email', authController.verifyEmail);

export default router;

// src/routes/shops.ts
import { Router } from 'express';
import { ShopController } from '@/controllers/shopController';
import { auth } from '@/middleware/auth';
import { cache } from '@/middleware/cache';

const router = Router();
const shopController = new ShopController();

// Public routes with caching
router.get('/', cache(300), shopController.getShops); // 5 min cache
router.get('/featured', cache(600), shopController.getFeaturedShops); // 10 min cache
router.get('/nearby', shopController.getNearbyShops);
router.get('/:id', cache(300), shopController.getShopById);
router.get('/:id/products', cache(180), shopController.getShopProducts); // 3 min cache
router.get('/:id/categories', cache(600), shopController.getShopCategories);

export default router;

// src/routes/orders.ts
import { Router } from 'express';
import { OrderController } from '@/controllers/orderController';
import { auth } from '@/middleware/auth';
import { validateRequest } from '@/middleware/validation';
import { createOrderSchema, updateOrderSchema } from '@/validators/orderValidators';

const router = Router();
const orderController = new OrderController();

// All order routes require authentication
router.use(auth);

router.post('/', validateRequest(createOrderSchema), orderController.createOrder);
router.get('/', orderController.getUserOrders);
router.get('/:id', orderController.getOrderById);
router.patch('/:id/cancel', orderController.cancelOrder);
router.patch('/:id/tip', validateRequest(updateOrderSchema), orderController.updateTip);
router.get('/:id/track', orderController.trackOrder);

export default router;

// src/routes/vendor.ts
import { Router } from 'express';
import { VendorController } from '@/controllers/vendorController';
import { auth } from '@/middleware/auth';
import { requireRole } from '@/middleware/requireRole';
import { validateRequest } from '@/middleware/validation';
import { updateShopSchema, createProductSchema } from '@/validators/vendorValidators';
import { upload } from '@/middleware/upload';

const router = Router();
const vendorController = new VendorController();

// All vendor routes require authentication and vendor role
router.use(auth);
router.use(requireRole(['VENDOR']));

// Shop management
router.get('/shop', vendorController.getVendorShop);
router.put('/shop', validateRequest(updateShopSchema), vendorController.updateShop);
router.patch('/shop/status', vendorController.toggleShopStatus);

// Product management
router.get('/products', vendorController.getVendorProducts);
router.post('/products', upload.array('images', 5), validateRequest(createProductSchema), vendorController.createProduct);
router.put('/products/:id', upload.array('images', 5), vendorController.updateProduct);
router.delete('/products/:id', vendorController.deleteProduct);

// Order management
router.get('/orders', vendorController.getVendorOrders);
router.patch('/orders/:id/status', vendorController.updateOrderStatus);
router.get('/orders/stats', vendorController.getOrderStats);

// Analytics
router.get('/analytics/sales', vendorController.getSalesAnalytics);
router.get('/analytics/products', vendorController.getProductAnalytics);

export default router;

// src/routes/delivery.ts
import { Router } from 'express';
import { DeliveryController } from '@/controllers/deliveryController';
import { auth } from '@/middleware/auth';
import { requireRole } from '@/middleware/requireRole';
import { validateRequest } from '@/middleware/validation';
import { updateLocationSchema } from '@/validators/deliveryValidators';

const router = Router();
const deliveryController = new DeliveryController();

// All delivery routes require authentication and delivery role
router.use(auth);
router.use(requireRole(['DELIVERY']));

// Order management
router.get('/orders', deliveryController.getAssignedOrders);
router.get('/orders/available', deliveryController.getAvailableOrders);
router.patch('/orders/:id/accept', deliveryController.acceptOrder);
router.patch('/orders/:id/pickup', deliveryController.markPickedUp);
router.patch('/orders/:id/delivered', deliveryController.markDelivered);

// Location tracking
router.patch('/orders/:id/location', validateRequest(updateLocationSchema), deliveryController.updateLocation);

// Performance
router.get('/stats', deliveryController.getDeliveryStats);
router.get('/earnings', deliveryController.getEarnings);

export default router;
import { Router } from 'express';
import { ShopController } from '@/controllers/shopController';
import { auth } from '@/middleware/auth';
import { cache } from '@/middleware/cache';
import { shopRateLimiter } from '@/middleware/rateLimiter';

const router = Router();
const shopController = new ShopController();

// Apply lenient rate limiter for shop endpoints (allows browsing)
router.use(shopRateLimiter);

// Public routes with caching
router.get('/', cache(300), shopController.getShops); // 5 min cache
router.get('/featured', cache(600), shopController.getFeaturedShops); // 10 min cache
router.get('/nearby', shopController.getNearbyShops);
router.get('/:id', cache(300), shopController.getShopById);
router.get('/:id/products', cache(180), shopController.getShopProducts); // 3 min cache
router.get('/:id/categories', cache(600), shopController.getShopCategories);

export default router; 
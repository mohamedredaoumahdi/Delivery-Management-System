"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const shopController_1 = require("@/controllers/shopController");
const cache_1 = require("@/middleware/cache");
const router = (0, express_1.Router)();
const shopController = new shopController_1.ShopController();
router.get('/', (0, cache_1.cache)(300), shopController.getShops);
router.get('/featured', (0, cache_1.cache)(600), shopController.getFeaturedShops);
router.get('/nearby', shopController.getNearbyShops);
router.get('/:id', (0, cache_1.cache)(300), shopController.getShopById);
router.get('/:id/products', (0, cache_1.cache)(180), shopController.getShopProducts);
router.get('/:id/categories', (0, cache_1.cache)(600), shopController.getShopCategories);
exports.default = router;
//# sourceMappingURL=shops.js.map
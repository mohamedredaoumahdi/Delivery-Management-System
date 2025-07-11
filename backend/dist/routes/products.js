"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const productController_1 = require("@/controllers/productController");
const auth_1 = require("@/middleware/auth");
const requireRole_1 = require("@/middleware/requireRole");
const validation_1 = require("@/middleware/validation");
const productValidators_1 = require("@/validators/productValidators");
const upload_1 = require("@/middleware/upload");
const router = (0, express_1.Router)();
const productController = new productController_1.ProductController();
router.get('/', productController.getProducts);
router.get('/:id', productController.getProductById);
router.get('/category/:categoryId', productController.getProductsByCategory);
router.get('/shop/:shopId', productController.getProductsByShop);
router.use(auth_1.auth);
router.post('/', (0, requireRole_1.requireRole)(['VENDOR']), upload_1.upload.array('images', 5), upload_1.resizeImages, (0, validation_1.validateRequest)(productValidators_1.createProductSchema), productController.createProduct);
router.put('/:id', (0, requireRole_1.requireRole)(['VENDOR']), upload_1.upload.array('images', 5), (0, validation_1.validateRequest)(productValidators_1.updateProductSchema), productController.updateProduct);
router.delete('/:id', (0, requireRole_1.requireRole)(['VENDOR']), productController.deleteProduct);
router.put('/:id/status', (0, requireRole_1.requireRole)(['VENDOR', 'ADMIN']), productController.updateProductStatus);
exports.default = router;
//# sourceMappingURL=products.js.map
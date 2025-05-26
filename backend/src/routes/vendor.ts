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
router.get('/orders/stats', vendorController.getOrderStats);
router.patch('/orders/:id/status', vendorController.updateOrderStatus);
router.patch('/orders/:id/cancellation-request', vendorController.handleCancellationRequest);
router.post('/orders/:id/cancel', vendorController.cancelOrder);

// Analytics
router.get('/analytics/sales', vendorController.getSalesAnalytics);
router.get('/analytics/products', vendorController.getProductAnalytics);

export default router; 
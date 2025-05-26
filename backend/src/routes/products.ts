import { Router } from 'express';
import { ProductController } from '@/controllers/productController';
import { auth } from '@/middleware/auth';
import { requireRole } from '@/middleware/requireRole';
import { validateRequest } from '@/middleware/validation';
import { createProductSchema, updateProductSchema } from '@/validators/productValidators';
import { upload } from '@/middleware/upload';

const router = Router();
const productController = new ProductController();

// Public routes
router.get('/', productController.getProducts);
router.get('/:id', productController.getProductById);
router.get('/category/:categoryId', productController.getProductsByCategory);
router.get('/shop/:shopId', productController.getProductsByShop);

// Protected routes (require authentication)
router.use(auth);

// Vendor routes
router.post('/', 
  requireRole('VENDOR'),
  upload.array('images', 5),
  validateRequest(createProductSchema),
  productController.createProduct
);

router.put('/:id',
  requireRole('VENDOR'),
  upload.array('images', 5),
  validateRequest(updateProductSchema),
  productController.updateProduct
);

router.delete('/:id',
  requireRole('VENDOR'),
  productController.deleteProduct
);

// Admin routes
router.put('/:id/status',
  requireRole('ADMIN'),
  productController.updateProductStatus
);

export default router; 
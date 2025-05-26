import { Router } from 'express';
import { AdminController } from '@/controllers/adminController';
import { auth } from '@/middleware/auth';
import { requireRole } from '@/middleware/requireRole';
import { validateRequest } from '@/middleware/validation';
import { upload } from '@/middleware/upload';
import { 
  updateUserSchema, 
  createShopSchema, 
  updateShopSchema,
  createCategorySchema,
  updateCategorySchema
} from '@/validators/adminValidators';

const router = Router();
const adminController = new AdminController();

// All admin routes require authentication and admin role
router.use(auth);
router.use(requireRole(['ADMIN']));

// User management
router.get('/users', adminController.getUsers);
router.get('/users/:id', adminController.getUserById);
router.put('/users/:id', validateRequest(updateUserSchema), adminController.updateUser);
router.delete('/users/:id', adminController.deleteUser);

// Shop management
router.get('/shops', adminController.getShops);
router.post('/shops', validateRequest(createShopSchema), adminController.createShop);
router.put('/shops/:id', validateRequest(updateShopSchema), adminController.updateShop);
router.delete('/shops/:id', adminController.deleteShop);

// Category management
router.get('/categories', adminController.getCategories);
router.post('/categories', upload.single('image'), validateRequest(createCategorySchema), adminController.createCategory);
router.put('/categories/:id', upload.single('image'), validateRequest(updateCategorySchema), adminController.updateCategory);
router.delete('/categories/:id', adminController.deleteCategory);

// Analytics
router.get('/analytics/users', adminController.getUserAnalytics);
router.get('/analytics/orders', adminController.getOrderAnalytics);
router.get('/analytics/revenue', adminController.getRevenueAnalytics);

export default router; 
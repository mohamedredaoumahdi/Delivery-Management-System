import { Router } from 'express';
import { AdminController } from '@/controllers/adminController';
import { auth } from '@/middleware/auth';
import { requireRole } from '@/middleware/requireRole';
import { validateRequest } from '@/middleware/validation';
import { upload } from '@/middleware/upload';
import { 
  createUserSchema, 
  updateUserSchema, 
  createShopSchema, 
  updateShopSchema,
  createCategorySchema,
  updateCategorySchema,
  assignDeliveryAgentSchema,
  cancelOrderSchema,
  refundOrderSchema,
  updateOrderFeesSchema,
  approveVendorSchema,
  rejectVendorSchema,
  suspendVendorSchema,
} from '@/validators/adminValidators';

const router = Router();
const adminController = new AdminController();

// All admin routes require authentication and admin role
router.use(auth);
router.use(requireRole(['ADMIN']));

// User management
router.get('/users', adminController.getUsers);
router.post('/users', validateRequest(createUserSchema), adminController.createUser);
router.get('/users/:id', adminController.getUserById);
router.put('/users/:id', validateRequest(updateUserSchema), adminController.updateUser);
router.delete('/users/:id', adminController.deleteUser);

// Dashboard overview
router.get('/dashboard/overview', adminController.getDashboardOverview);

// Shop management
router.get('/shops', adminController.getShops);
router.get('/shops/:id', adminController.getShopById);
router.post('/shops', validateRequest(createShopSchema), adminController.createShop);
router.put('/shops/:id', validateRequest(updateShopSchema), adminController.updateShop);
router.delete('/shops/:id', adminController.deleteShop);

// Vendor approval management
router.post('/shops/:id/approve', validateRequest(approveVendorSchema), adminController.approveVendor);
router.post('/shops/:id/reject', validateRequest(rejectVendorSchema), adminController.rejectVendor);
router.post('/shops/:id/suspend', validateRequest(suspendVendorSchema), adminController.suspendVendor);

// Vendor performance tracking
router.get('/shops/:id/performance', adminController.getVendorPerformance);

// Category management
router.get('/categories', adminController.getCategories);
router.post('/categories', upload.single('image'), validateRequest(createCategorySchema), adminController.createCategory);
router.put('/categories/:id', upload.single('image'), validateRequest(updateCategorySchema), adminController.updateCategory);
router.delete('/categories/:id', adminController.deleteCategory);

// Order management
router.get('/orders', adminController.getOrders);
router.get('/orders/:id', adminController.getOrderById);
router.put('/orders/:id/status', adminController.updateOrderStatus);
router.post('/orders/:id/assign-delivery', validateRequest(assignDeliveryAgentSchema), adminController.assignDeliveryAgent);
router.post('/orders/:id/cancel', validateRequest(cancelOrderSchema), adminController.cancelOrder);
router.post('/orders/:id/refund', validateRequest(refundOrderSchema), adminController.refundOrder);
router.put('/orders/:id/fees', validateRequest(updateOrderFeesSchema), adminController.updateOrderFees);
router.get('/delivery-agents', adminController.getAvailableDeliveryAgents);

// Analytics
router.get('/analytics/users', adminController.getUserAnalytics);
router.get('/analytics/orders', adminController.getOrderAnalytics);
router.get('/analytics/revenue', adminController.getRevenueAnalytics);

export default router; 
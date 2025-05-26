import { Router } from 'express';
import { UserController } from '@/controllers/userController';
import { auth } from '@/middleware/auth';
import { validateRequest } from '@/middleware/validation';
import { updateProfileSchema, changePasswordSchema } from '@/validators/userValidators';

const router = Router();
const userController = new UserController();

// All user routes require authentication
router.use(auth);

// Profile management
router.get('/profile', userController.getProfile);
router.put('/profile', validateRequest(updateProfileSchema), userController.updateProfile);
router.put('/password', validateRequest(changePasswordSchema), userController.changePassword);

// Address management
router.get('/addresses', userController.getAddresses);
router.post('/addresses', userController.addAddress);
router.put('/addresses/:id', userController.updateAddress);
router.delete('/addresses/:id', userController.deleteAddress);

// Order history
router.get('/orders', userController.getOrderHistory);
router.get('/orders/:id', userController.getOrderDetails);

// Favorites
router.get('/favorites', userController.getFavorites);
router.post('/favorites/:shopId', userController.addToFavorites);
router.delete('/favorites/:shopId', userController.removeFromFavorites);

export default router; 
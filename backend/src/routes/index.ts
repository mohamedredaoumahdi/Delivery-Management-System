// src/routes/index.ts
import { Router } from 'express';
import authRoutes from './auth';
import shopRoutes from './shops';
import orderRoutes from './orders';
import vendorRoutes from './vendor';
import deliveryRoutes from './delivery';
import adminRoutes from './admin';
import userRoutes from './users';
import productRoutes from './products';
import addressRoutes from './addresses';
import reviewRoutes from './reviews';
import paymentMethodRoutes from './paymentMethods';

const router = Router();

// Mount individual routers
router.use('/auth', authRoutes);
router.use('/shops', shopRoutes);
router.use('/orders', orderRoutes);
router.use('/vendor', vendorRoutes);
router.use('/delivery', deliveryRoutes);
router.use('/admin', adminRoutes);
router.use('/users', userRoutes);
router.use('/products', productRoutes);
router.use('/addresses', addressRoutes);
router.use('/reviews', reviewRoutes);
router.use('/users/payment-methods', paymentMethodRoutes);

export default router;
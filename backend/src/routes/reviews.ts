import { Router } from 'express';
import { ReviewController } from '@/controllers/reviewController';
import { auth } from '@/middleware/auth';
import { validateRequest } from '@/middleware/validation';
import { createReviewSchema, updateReviewSchema } from '@/validators/reviewValidators';

const router = Router();
const reviewController = new ReviewController();

// All review routes require authentication
router.use(auth);

// Review management
router.post('/', validateRequest(createReviewSchema), reviewController.createReview);
router.put('/:id', validateRequest(updateReviewSchema), reviewController.updateReview);
router.delete('/:id', reviewController.deleteReview);

// Get reviews
router.get('/shop/:shopId', reviewController.getShopReviews);
router.get('/product/:productId', reviewController.getProductReviews);
router.get('/user', reviewController.getUserReviews);

export default router; 
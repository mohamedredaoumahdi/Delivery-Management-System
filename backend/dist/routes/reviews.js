"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const reviewController_1 = require("@/controllers/reviewController");
const auth_1 = require("@/middleware/auth");
const validation_1 = require("@/middleware/validation");
const reviewValidators_1 = require("@/validators/reviewValidators");
const router = (0, express_1.Router)();
const reviewController = new reviewController_1.ReviewController();
router.use(auth_1.auth);
router.post('/', (0, validation_1.validateRequest)(reviewValidators_1.createReviewSchema), reviewController.createReview);
router.put('/:id', (0, validation_1.validateRequest)(reviewValidators_1.updateReviewSchema), reviewController.updateReview);
router.delete('/:id', reviewController.deleteReview);
router.get('/shop/:shopId', reviewController.getShopReviews);
router.get('/product/:productId', reviewController.getProductReviews);
router.get('/user', reviewController.getUserReviews);
exports.default = router;
//# sourceMappingURL=reviews.js.map
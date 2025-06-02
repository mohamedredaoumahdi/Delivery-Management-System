"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReviewController = void 0;
const database_1 = require("@/config/database");
const catchAsync_1 = require("@/utils/catchAsync");
class ReviewController {
    createReview = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { rating, comment, shopId, productId } = req.body;
        const review = await database_1.prisma.review.create({
            data: {
                rating,
                comment,
                shopId,
                productId,
                userId: req.user.id,
            },
        });
        res.status(201).json({ status: 'success', data: review });
    });
    updateReview = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const review = await database_1.prisma.review.update({
            where: { id: req.params.id },
            data: req.body,
        });
        res.json({ status: 'success', data: review });
    });
    deleteReview = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        await database_1.prisma.review.delete({ where: { id: req.params.id } });
        res.json({ status: 'success', data: null });
    });
    getShopReviews = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const reviews = await database_1.prisma.review.findMany({
            where: { shopId: req.params.shopId },
            include: { user: true },
        });
        res.json({ status: 'success', data: reviews });
    });
    getProductReviews = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const reviews = await database_1.prisma.review.findMany({
            where: { productId: req.params.productId },
            include: { user: true },
        });
        res.json({ status: 'success', data: reviews });
    });
    getUserReviews = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const reviews = await database_1.prisma.review.findMany({
            where: { userId: req.user.id },
            include: { shop: true, product: true },
        });
        res.json({ status: 'success', data: reviews });
    });
}
exports.ReviewController = ReviewController;
//# sourceMappingURL=reviewController.js.map
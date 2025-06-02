"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ShopController = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const catchAsync_1 = require("@/utils/catchAsync");
const prisma = new client_1.PrismaClient();
class ShopController {
    getShops = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { q: query, category, lat, lng, radius, page = 1, limit = 20 } = req.query;
        const where = { isActive: true };
        if (category && typeof category === 'string') {
            where.category = category.toUpperCase();
        }
        if (query && typeof query === 'string') {
            where.name = { contains: query, mode: 'insensitive' };
        }
        const skip = (Number(page) - 1) * Number(limit);
        const take = Number(limit);
        const shops = await prisma.shop.findMany({
            where,
            orderBy: { rating: 'desc' },
            skip,
            take,
        });
        return res.json({ status: 'success', data: shops });
    });
    getFeaturedShops = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { limit = 10 } = req.query;
        const shops = await prisma.shop.findMany({
            where: {
                isActive: true,
                isFeatured: true,
            },
            orderBy: { rating: 'desc' },
            take: Number(limit),
        });
        return res.json({ status: 'success', data: shops });
    });
    getNearbyShops = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { lat, lng, radius = 5 } = req.query;
        if (!lat || !lng) {
            throw new appError_1.AppError('Location coordinates are required', 400);
        }
        const shops = await prisma.shop.findMany({
            where: {
                isActive: true,
            },
            take: 20,
        });
        return res.json({ status: 'success', data: shops });
    });
    getShopById = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const shop = await prisma.shop.findUnique({
            where: { id: req.params.id },
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        return res.json({ status: 'success', data: shop });
    });
    getShopProducts = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { q: query, category, in_stock: inStock, featured, page = 1, limit = 20 } = req.query;
        const where = {
            shopId: req.params.id,
            isActive: true,
        };
        if (category && typeof category === 'string') {
            where.categoryName = {
                equals: category,
                mode: 'insensitive'
            };
        }
        if (query && typeof query === 'string') {
            where.OR = [
                { name: { contains: query, mode: 'insensitive' } },
                { description: { contains: query, mode: 'insensitive' } },
                { tags: { has: query } },
            ];
        }
        if (inStock !== undefined) {
            where.inStock = inStock === 'true';
        }
        if (featured !== undefined) {
            where.isFeatured = featured === 'true';
        }
        const skip = (Number(page) - 1) * Number(limit);
        const take = Number(limit);
        const products = await prisma.product.findMany({
            where,
            orderBy: { createdAt: 'desc' },
            skip,
            take,
        });
        return res.json({ status: 'success', data: products });
    });
    getShopCategories = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const categories = await prisma.category.findMany({
            where: {
                shopId: req.params.id,
                status: 'ACTIVE',
            },
            orderBy: { name: 'asc' },
        });
        return res.json({ status: 'success', data: categories });
    });
}
exports.ShopController = ShopController;
//# sourceMappingURL=shopController.js.map
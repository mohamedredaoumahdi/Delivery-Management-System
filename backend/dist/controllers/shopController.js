"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ShopController = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const catchAsync_1 = require("@/utils/catchAsync");
const prisma = new client_1.PrismaClient();
class ShopController {
    getShops = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const shops = await prisma.shop.findMany({
            where: { isActive: true },
            orderBy: { rating: 'desc' },
        });
        return res.json(shops);
    });
    getFeaturedShops = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const shops = await prisma.shop.findMany({
            where: {
                isActive: true,
                isFeatured: true,
            },
            orderBy: { rating: 'desc' },
            take: 10,
        });
        return res.json(shops);
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
        return res.json(shops);
    });
    getShopById = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const shop = await prisma.shop.findUnique({
            where: { id: req.params.id },
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        return res.json(shop);
    });
    getShopProducts = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const products = await prisma.product.findMany({
            where: {
                shopId: req.params.id,
                isActive: true,
            },
            orderBy: { createdAt: 'desc' },
        });
        return res.json(products);
    });
    getShopCategories = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const categories = await prisma.category.findMany({
            where: {
                shopId: req.params.id,
                status: 'ACTIVE',
            },
            orderBy: { name: 'asc' },
        });
        return res.json(categories);
    });
}
exports.ShopController = ShopController;
//# sourceMappingURL=shopController.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VendorController = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const prisma = new client_1.PrismaClient();
class VendorController {
    async getShop(req, res) {
        const shop = await prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        res.json(shop);
    }
    async updateShop(req, res) {
        const shop = await prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { name, description, logoUrl } = req.body;
        const updatedShop = await prisma.shop.update({
            where: { id: shop.id },
            data: {
                name,
                description,
                logoUrl,
                isActive: true
            }
        });
        res.json(updatedShop);
    }
    async getProducts(req, res) {
        const shop = await prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const products = await prisma.product.findMany({
            where: {
                shopId: shop.id
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
        res.json(products);
    }
    async createProduct(req, res) {
        const shop = await prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { name, description, price, categoryId, images } = req.body;
        const product = await prisma.product.create({
            data: {
                name,
                description,
                price,
                categoryId,
                images,
                categoryName: (await prisma.category.findUnique({ where: { id: categoryId } })).name,
                shopId: shop.id
            }
        });
        res.status(201).json(product);
    }
    async updateProduct(req, res) {
        const shop = await prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { id } = req.params;
        const { name, description, price, categoryId, images } = req.body;
        const product = await prisma.product.update({
            where: {
                id,
                shopId: shop.id
            },
            data: {
                name,
                description,
                price,
                categoryId,
                images
            }
        });
        if (!product) {
            throw new appError_1.AppError('Product not found', 404);
        }
        res.json(product);
    }
    async deleteProduct(req, res) {
        const shop = await prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { id } = req.params;
        const product = await prisma.product.delete({
            where: {
                id,
                shopId: shop.id
            }
        });
        if (!product) {
            throw new appError_1.AppError('Product not found', 404);
        }
        res.json({ message: 'Product deleted successfully' });
    }
    async getVendorOrders(req, res) {
        const shop = await prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const orders = await prisma.order.findMany({
            where: {
                shopId: shop.id
            },
            include: {
                user: {
                    select: {
                        name: true,
                        phone: true,
                        addresses: true
                    }
                },
                items: {
                    include: {
                        product: true
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
        res.json(orders);
    }
    async updateOrderStatus(req, res) {
        const shop = await prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { id } = req.params;
        const { status } = req.body;
        const order = await prisma.order.update({
            where: {
                id,
                shopId: shop.id
            },
            data: {
                status: status
            }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found', 404);
        }
        res.json(order);
    }
    async getOrderStats(req, res) {
        const shop = await prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const stats = await prisma.order.aggregate({
            _count: {
                id: true
            },
            _sum: {
                total: true
            },
            _avg: {
                total: true
            }
        });
        res.json(stats);
    }
    async getSalesAnalytics(req, res) {
        const { startDate, endDate } = req.query;
        const where = {
            shopId: req.user.id,
            status: client_1.OrderStatus.DELIVERED
        };
        if (startDate && endDate) {
            where.deliveredAt = {
                gte: new Date(startDate),
                lte: new Date(endDate)
            };
        }
        const sales = await prisma.order.aggregate({
            _count: {
                id: true
            },
            _sum: {
                total: true
            },
            _avg: {
                total: true
            }
        });
        res.json(sales);
    }
    async getProductAnalytics(req, res) {
        const shop = await prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const products = await prisma.order.aggregate({
            _count: {
                id: true
            },
            _sum: {
                total: true
            },
            _avg: {
                total: true
            }
        });
        res.json(products);
    }
}
exports.VendorController = VendorController;
//# sourceMappingURL=vendorController.js.map
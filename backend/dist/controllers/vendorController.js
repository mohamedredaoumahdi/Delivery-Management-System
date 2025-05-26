"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VendorController = void 0;
const client_1 = require("@prisma/client");
const AppError_1 = require("@/utils/appError");
const prisma = new client_1.PrismaClient();
class VendorController {
    async getShop(req, res) {
        const shop = await prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        res.json(shop);
    }
    async updateShop(req, res) {
        const shop = await prisma.shop.update({
            where: {
                ownerId: req.user.id
            },
            data: req.body
        });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        res.json(shop);
    }
    async updateShopStatus(req, res) {
        const { status } = req.body;
        const shop = await prisma.shop.update({
            where: {
                ownerId: req.user.id
            },
            data: {
                status: status
            }
        });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        res.json(shop);
    }
    async getProducts(req, res) {
        const shop = await prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
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
        const { name, description, price, categoryId, images } = req.body;
        const product = await prisma.product.create({
            data: {
                name,
                description,
                price,
                categoryId,
                images,
                shopId: req.user.id
            }
        });
        res.status(201).json(product);
    }
    async updateProduct(req, res) {
        const { id } = req.params;
        const { name, description, price, categoryId, images } = req.body;
        const product = await prisma.product.update({
            where: {
                id,
                shopId: req.user.id
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
            throw new AppError_1.AppError('Product not found', 404);
        }
        res.json(product);
    }
    async deleteProduct(req, res) {
        const { id } = req.params;
        const product = await prisma.product.delete({
            where: {
                id,
                shopId: req.user.id
            }
        });
        if (!product) {
            throw new AppError_1.AppError('Product not found', 404);
        }
        res.json({ message: 'Product deleted successfully' });
    }
    async getVendorOrders(req, res) {
        const orders = await prisma.order.findMany({
            where: {
                shopId: req.user.id
            },
            include: {
                user: {
                    select: {
                        name: true,
                        phone: true,
                        address: true
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
        const { id } = req.params;
        const { status } = req.body;
        const order = await prisma.order.update({
            where: {
                id,
                shopId: req.user.id
            },
            data: {
                status: status
            }
        });
        if (!order) {
            throw new AppError_1.AppError('Order not found', 404);
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
            throw new AppError_1.AppError('Shop not found', 404);
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
            status: OrderStatus.DELIVERED
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
            throw new AppError_1.AppError('Shop not found', 404);
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
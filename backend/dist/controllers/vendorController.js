"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VendorController = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const catchAsync_1 = require("@/utils/catchAsync");
const database_1 = require("@/config/database");
const prismaClient = new client_1.PrismaClient();
class VendorController {
    async getShop(req, res) {
        const shop = await prismaClient.shop.findFirst({
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
        const shop = await prismaClient.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { name, description, logoUrl } = req.body;
        const updatedShop = await prismaClient.shop.update({
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
        const shop = await database_1.prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const products = await database_1.prisma.product.findMany({
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
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { name, description, price, categoryId, images } = req.body;
        const product = await database_1.prisma.product.create({
            data: {
                name,
                description,
                price,
                categoryId,
                images,
                categoryName: (await database_1.prisma.category.findUnique({ where: { id: categoryId } })).name,
                shopId: shop.id
            }
        });
        res.status(201).json({ status: 'success', data: product });
    }
    async updateProduct(req, res) {
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { id } = req.params;
        const { name, description, price, categoryId, images, inStock, isActive } = req.body;
        const product = await database_1.prisma.product.update({
            where: {
                id,
                shopId: shop.id
            },
            data: {
                name,
                description,
                price,
                categoryId,
                images,
                inStock,
                isActive
            }
        });
        if (!product) {
            throw new appError_1.AppError('Product not found', 404);
        }
        res.json({ status: 'success', data: product });
    }
    async deleteProduct(req, res) {
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { id } = req.params;
        const product = await database_1.prisma.product.delete({
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
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const orders = await database_1.prisma.order.findMany({
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
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { id } = req.params;
        const { status } = req.body;
        const order = await database_1.prisma.order.update({
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
        const shop = await database_1.prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const stats = await database_1.prisma.order.aggregate({
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
        const sales = await database_1.prisma.order.aggregate({
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
        const shop = await database_1.prisma.shop.findFirst({
            where: {
                ownerId: req.user.id
            }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const products = await database_1.prisma.order.aggregate({
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
    getVendorShop = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id },
            include: { categories: true },
        });
        res.json({ status: 'success', data: shop });
    });
    createShop = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const existingShop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id },
        });
        if (existingShop) {
            throw new appError_1.AppError('Shop already exists', 400);
        }
        const { name, description, category, address, latitude, longitude, phone, email, openingHours, hasDelivery = true, hasPickup = true, minimumOrderAmount = 0, deliveryFee = 0, estimatedDeliveryTime = 30 } = req.body;
        const shop = await database_1.prisma.shop.create({
            data: {
                name,
                description,
                category,
                address,
                latitude,
                longitude,
                phone,
                email,
                openingHours,
                hasDelivery,
                hasPickup,
                minimumOrderAmount,
                deliveryFee,
                estimatedDeliveryTime,
                ownerId: req.user.id,
                isActive: true,
                isOpen: true,
            },
            include: { categories: true },
        });
        res.status(201).json({ status: 'success', data: shop });
    });
    toggleShopStatus = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id },
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const updatedShop = await database_1.prisma.shop.update({
            where: { id: shop.id },
            data: { isActive: !shop.isActive },
        });
        res.json({ status: 'success', data: updatedShop });
    });
    getVendorProducts = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id },
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const products = await database_1.prisma.product.findMany({
            where: { shopId: shop.id },
            include: { category: true },
        });
        res.json({ status: 'success', data: products });
    });
    async handleCancellationRequest(req, res) {
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { id } = req.params;
        const { action } = req.body;
        const order = await database_1.prisma.order.findFirst({
            where: {
                id,
                shopId: shop.id,
                status: client_1.OrderStatus.CANCELLATION_REQUESTED
            }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found or not in cancellation requested status', 404);
        }
        const updatedOrder = await database_1.prisma.order.update({
            where: {
                id: order.id
            },
            data: {
                status: action === 'approve' ? client_1.OrderStatus.CANCELLED : client_1.OrderStatus.PENDING,
                cancellationReason: action === 'approve' ?
                    'Cancellation approved by vendor' :
                    'Cancellation request rejected by vendor'
            }
        });
        res.json(updatedOrder);
    }
    async cancelOrder(req, res) {
        const shop = await database_1.prisma.shop.findFirst({
            where: { ownerId: req.user.id }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        const { id } = req.params;
        const { reason } = req.body;
        const order = await database_1.prisma.order.findFirst({
            where: {
                id,
                shopId: shop.id,
                status: {
                    in: [client_1.OrderStatus.PENDING, client_1.OrderStatus.ACCEPTED, client_1.OrderStatus.PREPARING]
                }
            }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found or cannot be cancelled in current status', 404);
        }
        const updatedOrder = await database_1.prisma.order.update({
            where: {
                id: order.id
            },
            data: {
                status: client_1.OrderStatus.CANCELLED,
                cancellationReason: reason || 'Cancelled by vendor'
            }
        });
        res.json(updatedOrder);
    }
}
exports.VendorController = VendorController;
//# sourceMappingURL=vendorController.js.map
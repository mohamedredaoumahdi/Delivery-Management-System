"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderController = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const prisma = new client_1.PrismaClient();
class OrderController {
    async createOrder(req, res) {
        const { items, shopId, deliveryAddress, paymentMethod } = req.body;
        const order = await prisma.order.create({
            data: {
                userId: req.user.id,
                shopId,
                shopName: req.body.shopName,
                orderNumber: `ORD-${Date.now()}`,
                deliveryAddress,
                deliveryLatitude: req.body.deliveryLatitude,
                deliveryLongitude: req.body.deliveryLongitude,
                paymentMethod,
                status: client_1.OrderStatus.PENDING,
                subtotal: items.reduce((sum, item) => sum + (item.price * item.quantity), 0),
                deliveryFee: req.body.deliveryFee || 0,
                serviceFee: req.body.serviceFee || 0,
                tax: req.body.tax || 0,
                total: items.reduce((sum, item) => sum + (item.price * item.quantity), 0) +
                    (req.body.deliveryFee || 0) +
                    (req.body.serviceFee || 0) +
                    (req.body.tax || 0),
                items: {
                    create: items.map((item) => ({
                        productId: item.productId,
                        quantity: item.quantity,
                        price: item.price
                    }))
                }
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true
                    }
                },
                items: {
                    include: {
                        product: {
                            select: {
                                name: true,
                                price: true
                            }
                        }
                    }
                }
            }
        });
        res.status(201).json(order);
    }
    async getUserOrders(req, res) {
        const orders = await prisma.order.findMany({
            where: {
                userId: req.user.id
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true
                    }
                },
                items: {
                    include: {
                        product: {
                            select: {
                                name: true,
                                price: true
                            }
                        }
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
        res.json(orders);
    }
    async getOrderById(req, res) {
        const order = await prisma.order.findFirst({
            where: {
                id: req.params.id,
                userId: req.user.id
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true
                    }
                },
                items: {
                    include: {
                        product: {
                            select: {
                                name: true,
                                price: true
                            }
                        }
                    }
                }
            }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found', 404);
        }
        res.json(order);
    }
    async cancelOrder(req, res) {
        const order = await prisma.order.findFirst({
            where: {
                id: req.params.id,
                userId: req.user.id
            }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found', 404);
        }
        if (order.status !== client_1.OrderStatus.PENDING) {
            throw new appError_1.AppError('Cannot cancel order in current status', 400);
        }
        const updatedOrder = await prisma.order.update({
            where: {
                id: order.id
            },
            data: {
                status: client_1.OrderStatus.CANCELLED
            }
        });
        res.json(updatedOrder);
    }
    async updateTip(req, res) {
        const { tip } = req.body;
        const order = await prisma.order.findFirst({
            where: {
                id: req.params.id,
                userId: req.user.id
            }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found', 404);
        }
        if (order.status !== client_1.OrderStatus.DELIVERED) {
            throw new appError_1.AppError('Can only update tip for delivered orders', 400);
        }
        const updatedOrder = await prisma.order.update({
            where: {
                id: order.id
            },
            data: {
                tip
            }
        });
        res.json(updatedOrder);
    }
    async trackOrder(req, res) {
        const order = await prisma.order.findFirst({
            where: {
                id: req.params.id,
                userId: req.user.id
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true
                    }
                },
                items: {
                    include: {
                        product: {
                            select: {
                                name: true,
                                price: true
                            }
                        }
                    }
                }
            }
        });
        if (!order) {
            throw new appError_1.AppError('Order not found', 404);
        }
        res.json({
            status: order.status,
            estimatedDeliveryTime: order.estimatedDeliveryTime,
        });
    }
}
exports.OrderController = OrderController;
//# sourceMappingURL=orderController.js.map
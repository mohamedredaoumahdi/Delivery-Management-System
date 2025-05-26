"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DeliveryController = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const prisma = new client_1.PrismaClient();
class DeliveryController {
    async getAssignedOrders(req, res) {
        const orders = await prisma.order.findMany({
            where: {
                status: {
                    in: [client_1.OrderStatus.ACCEPTED, client_1.OrderStatus.READY_FOR_PICKUP, client_1.OrderStatus.IN_DELIVERY]
                }
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true,
                    }
                },
                user: {
                    select: {
                        name: true,
                        phone: true,
                        addresses: true
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
        res.json(orders);
    }
    async getAvailableOrders(req, res) {
        const orders = await prisma.order.findMany({
            where: {
                status: client_1.OrderStatus.READY_FOR_PICKUP,
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true,
                    }
                },
                user: {
                    select: {
                        name: true,
                        phone: true,
                        addresses: true
                    }
                }
            },
            orderBy: {
                createdAt: 'asc'
            }
        });
        res.json(orders);
    }
    async acceptOrder(req, res) {
        const { id } = req.params;
        const order = await prisma.order.update({
            where: {
                id,
                status: client_1.OrderStatus.READY_FOR_PICKUP,
            },
            data: {
                status: client_1.OrderStatus.ACCEPTED
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true,
                    }
                },
                user: {
                    select: {
                        name: true,
                        phone: true,
                        addresses: true
                    }
                }
            }
        });
        if (!order) {
            throw new appError_1.AppError('Order not available for delivery', 400);
        }
        res.json(order);
    }
    async updateOrderStatus(req, res) {
        const { id } = req.params;
        const { status } = req.body;
        const order = await prisma.order.update({
            where: {
                id,
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
    async updateLocation(req, res) {
        const { latitude, longitude } = req.body;
        res.json({ message: 'Location update not supported' });
    }
    async getDeliveryHistory(req, res) {
        const orders = await prisma.order.findMany({
            where: {
                status: client_1.OrderStatus.DELIVERED
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true,
                    }
                },
                user: {
                    select: {
                        name: true,
                        addresses: true
                    }
                }
            },
            orderBy: {
                deliveredAt: 'desc'
            }
        });
        res.json(orders);
    }
}
exports.DeliveryController = DeliveryController;
//# sourceMappingURL=deliveryController.js.map
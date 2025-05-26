"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DeliveryController = void 0;
const client_1 = require("@prisma/client");
const AppError_1 = require("@/utils/appError");
const prisma = new client_1.PrismaClient();
class DeliveryController {
    async getAssignedOrders(req, res) {
        const orders = await prisma.order.findMany({
            where: {
                deliveryId: req.user.id,
                status: {
                    in: [client_1.OrderStatus.ACCEPTED, client_1.OrderStatus.PICKED_UP, client_1.OrderStatus.IN_TRANSIT]
                }
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true,
                        location: true
                    }
                },
                user: {
                    select: {
                        name: true,
                        phone: true,
                        address: true
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
                status: client_1.OrderStatus.READY_FOR_DELIVERY,
                deliveryId: null
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true,
                        location: true
                    }
                },
                user: {
                    select: {
                        name: true,
                        phone: true,
                        address: true
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
                status: client_1.OrderStatus.READY_FOR_DELIVERY,
                deliveryId: null
            },
            data: {
                deliveryId: req.user.id,
                status: client_1.OrderStatus.ACCEPTED
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true,
                        location: true
                    }
                },
                user: {
                    select: {
                        name: true,
                        phone: true,
                        address: true
                    }
                }
            }
        });
        if (!order) {
            throw new AppError_1.AppError('Order not available for delivery', 400);
        }
        res.json(order);
    }
    async updateOrderStatus(req, res) {
        const { id } = req.params;
        const { status } = req.body;
        const order = await prisma.order.update({
            where: {
                id,
                deliveryId: req.user.id
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
    async updateLocation(req, res) {
        const { latitude, longitude } = req.body;
        const delivery = await prisma.delivery.update({
            where: {
                id: req.user.id
            },
            data: {
                currentLocation: {
                    latitude,
                    longitude
                }
            }
        });
        res.json(delivery);
    }
    async getDeliveryHistory(req, res) {
        const orders = await prisma.order.findMany({
            where: {
                deliveryId: req.user.id,
                status: client_1.OrderStatus.DELIVERED
            },
            include: {
                shop: {
                    select: {
                        name: true,
                        address: true
                    }
                },
                user: {
                    select: {
                        name: true,
                        address: true
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
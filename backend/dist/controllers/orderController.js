"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderController = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const prisma = new client_1.PrismaClient();
class OrderController {
    async createOrder(req, res) {
        const { items, shopId, deliveryAddress, deliveryLatitude, deliveryLongitude, deliveryInstructions, paymentMethod, tip = 0 } = req.body;
        const validPaymentMethods = Object.values(client_1.PaymentMethod);
        if (!validPaymentMethods.includes(paymentMethod)) {
            throw new appError_1.AppError('Invalid payment method', 400);
        }
        const shop = await prisma.shop.findUnique({
            where: { id: shopId },
            select: {
                name: true,
                deliveryFee: true,
                minimumOrderAmount: true,
                isActive: true,
                isOpen: true
            }
        });
        if (!shop) {
            throw new appError_1.AppError('Shop not found', 404);
        }
        if (!shop.isActive || !shop.isOpen) {
            throw new appError_1.AppError('Shop is currently not accepting orders', 400);
        }
        const productIds = items.map((item) => item.productId);
        const products = await prisma.product.findMany({
            where: {
                id: { in: productIds },
                shopId: shopId,
                isActive: true
            },
            select: {
                id: true,
                price: true,
                name: true,
                inStock: true,
                stockQuantity: true
            }
        });
        const productMap = new Map(products.map(p => [p.id, p]));
        for (const item of items) {
            const product = productMap.get(item.productId);
            if (!product) {
                throw new appError_1.AppError(`Product with ID ${item.productId} not found or not available`, 404);
            }
            if (!product.inStock || (product.stockQuantity !== null && product.stockQuantity < item.quantity)) {
                throw new appError_1.AppError(`Product ${product.name} is out of stock or has insufficient quantity`, 400);
            }
        }
        const subtotal = items.reduce((sum, item) => {
            const product = productMap.get(item.productId);
            return sum + (product.price * item.quantity);
        }, 0);
        if (subtotal < shop.minimumOrderAmount) {
            throw new appError_1.AppError(`Minimum order amount is $${shop.minimumOrderAmount}`, 400);
        }
        const deliveryFee = shop.deliveryFee || 0;
        const serviceFee = Math.round((subtotal * 0.05) * 100) / 100;
        const tax = Math.round((subtotal * 0.08) * 100) / 100;
        const total = subtotal + deliveryFee + serviceFee + tax + tip;
        const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 4).toUpperCase()}`;
        const order = await prisma.order.create({
            data: {
                userId: req.user.id,
                shopId,
                shopName: shop.name,
                orderNumber,
                deliveryAddress,
                deliveryLatitude: deliveryLatitude || 0.0,
                deliveryLongitude: deliveryLongitude || 0.0,
                deliveryInstructions,
                paymentMethod: paymentMethod,
                status: client_1.OrderStatus.PENDING,
                subtotal,
                deliveryFee,
                serviceFee,
                tax,
                tip,
                discount: 0,
                total,
                items: {
                    create: items.map((item) => {
                        const product = productMap.get(item.productId);
                        return {
                            productId: item.productId,
                            productName: product.name,
                            quantity: item.quantity,
                            productPrice: product.price,
                            totalPrice: product.price * item.quantity,
                            instructions: item.instructions || null
                        };
                    })
                }
            },
            include: {
                shop: {
                    select: {
                        id: true,
                        name: true,
                        address: true,
                        phone: true
                    }
                },
                items: {
                    include: {
                        product: {
                            select: {
                                id: true,
                                name: true,
                                price: true,
                                imageUrl: true
                            }
                        }
                    }
                }
            }
        });
        for (const item of items) {
            const product = productMap.get(item.productId);
            if (product && product.stockQuantity !== null) {
                await prisma.product.update({
                    where: { id: item.productId },
                    data: {
                        stockQuantity: {
                            decrement: item.quantity
                        }
                    }
                });
            }
        }
        let updatedStatus = client_1.OrderStatus.PENDING;
        switch (paymentMethod) {
            case client_1.PaymentMethod.CASH_ON_DELIVERY:
                updatedStatus = client_1.OrderStatus.ACCEPTED;
                break;
            case client_1.PaymentMethod.CARD:
            case client_1.PaymentMethod.WALLET:
            case client_1.PaymentMethod.BANK_TRANSFER:
                updatedStatus = client_1.OrderStatus.ACCEPTED;
                break;
        }
        if (updatedStatus !== client_1.OrderStatus.PENDING) {
            await prisma.order.update({
                where: { id: order.id },
                data: { status: updatedStatus }
            });
        }
        res.status(201).json({
            status: 'success',
            data: {
                ...order,
                status: updatedStatus
            }
        });
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
        res.json({ status: 'success', data: orders });
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
        if (order.status !== client_1.OrderStatus.PENDING && order.status !== client_1.OrderStatus.ACCEPTED) {
            throw new appError_1.AppError('Cannot request cancellation for order in current status', 400);
        }
        const updatedOrder = await prisma.order.update({
            where: {
                id: order.id
            },
            data: {
                status: client_1.OrderStatus.CANCELLATION_REQUESTED,
                cancellationReason: req.body.reason || 'Cancellation requested by customer'
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
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DeliveryController = void 0;
const database_1 = require("@/config/database");
const catchAsync_1 = require("@/utils/catchAsync");
class DeliveryController {
    getAssignedOrders = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const orders = await database_1.prisma.order.findMany({
            where: {
                deliveryPersonId: req.user.id,
            },
            include: {
                items: true,
                shop: true,
                user: true,
            },
        });
        res.json({
            status: 'success',
            data: orders,
        });
    });
    getAvailableOrders = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const orders = await database_1.prisma.order.findMany({
            where: {
                status: 'READY_FOR_PICKUP',
                deliveryPersonId: null,
            },
            include: {
                items: true,
                shop: true,
                user: true,
            },
        });
        res.json({
            status: 'success',
            data: orders,
        });
    });
    acceptOrder = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const order = await database_1.prisma.order.update({
            where: { id: req.params.id },
            data: {
                deliveryPersonId: req.user.id,
                status: 'IN_DELIVERY',
            },
        });
        res.json({
            status: 'success',
            data: order,
        });
    });
    markPickedUp = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const order = await database_1.prisma.order.update({
            where: { id: req.params.id },
            data: {
                status: 'IN_DELIVERY',
            },
        });
        res.json({
            status: 'success',
            data: order,
        });
    });
    markDelivered = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const order = await database_1.prisma.order.update({
            where: { id: req.params.id },
            data: {
                status: 'DELIVERED',
                deliveredAt: new Date(),
            },
        });
        res.json({
            status: 'success',
            data: order,
        });
    });
    updateLocation = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { latitude, longitude } = req.body;
        await database_1.prisma.deliveryLocation.create({
            data: {
                userId: req.user.id,
                latitude,
                longitude,
            },
        });
        res.json({
            status: 'success',
            message: 'Location updated successfully',
        });
    });
    getDeliveryStats = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const stats = await database_1.prisma.order.groupBy({
            by: ['status'],
            where: {
                deliveryPersonId: req.user.id,
            },
            _count: true,
        });
        res.json({
            status: 'success',
            data: stats,
        });
    });
    getEarnings = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const earnings = await database_1.prisma.order.aggregate({
            where: {
                deliveryPersonId: req.user.id,
                status: 'DELIVERED',
            },
            _sum: {
                deliveryFee: true,
            },
        });
        res.json({
            status: 'success',
            data: {
                totalEarnings: earnings._sum?.deliveryFee || 0,
            },
        });
    });
}
exports.DeliveryController = DeliveryController;
//# sourceMappingURL=deliveryController.js.map
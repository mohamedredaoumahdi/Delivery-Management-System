"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DeliveryController = void 0;
const Order_1 = require("@/models/Order");
const AppError_1 = require("@/utils/AppError");
class DeliveryController {
    async getAssignedOrders(req, res) {
        const orders = await Order_1.Order.find({
            delivery: req.user.id,
            status: { $in: ['ACCEPTED', 'PICKED_UP', 'IN_TRANSIT'] }
        })
            .populate([
            { path: 'shop', select: 'name address location' },
            { path: 'user', select: 'name phone address' }
        ])
            .sort({ createdAt: -1 });
        res.json(orders);
    }
    async getAvailableOrders(req, res) {
        const orders = await Order_1.Order.find({
            status: 'PENDING',
            delivery: null
        })
            .populate([
            { path: 'shop', select: 'name address location' },
            { path: 'user', select: 'name phone address' }
        ])
            .sort({ createdAt: 1 });
        res.json(orders);
    }
    async acceptOrder(req, res) {
        const order = await Order_1.Order.findOne({
            _id: req.params.id,
            status: 'PENDING',
            delivery: null
        });
        if (!order) {
            throw new AppError_1.AppError('Order not available for delivery', 400);
        }
        order.delivery = req.user.id;
        order.status = 'ACCEPTED';
        await order.save();
        res.json(order);
    }
    async markPickedUp(req, res) {
        const order = await Order_1.Order.findOne({
            _id: req.params.id,
            delivery: req.user.id,
            status: 'ACCEPTED'
        });
        if (!order) {
            throw new AppError_1.AppError('Order not found or cannot be picked up', 400);
        }
        order.status = 'PICKED_UP';
        await order.save();
        res.json(order);
    }
    async markDelivered(req, res) {
        const order = await Order_1.Order.findOne({
            _id: req.params.id,
            delivery: req.user.id,
            status: 'IN_TRANSIT'
        });
        if (!order) {
            throw new AppError_1.AppError('Order not found or cannot be marked as delivered', 400);
        }
        order.status = 'DELIVERED';
        order.deliveredAt = new Date();
        await order.save();
        res.json(order);
    }
    async updateLocation(req, res) {
        const { location } = req.body;
        const order = await Order_1.Order.findOne({
            _id: req.params.id,
            delivery: req.user.id,
            status: { $in: ['PICKED_UP', 'IN_TRANSIT'] }
        });
        if (!order) {
            throw new AppError_1.AppError('Order not found or cannot update location', 400);
        }
        order.currentLocation = location;
        await order.save();
        res.json(order);
    }
    async getDeliveryStats(req, res) {
        const stats = await Order_1.Order.aggregate([
            {
                $match: {
                    delivery: req.user.id,
                    status: 'DELIVERED'
                }
            },
            {
                $group: {
                    _id: null,
                    totalDeliveries: { $sum: 1 },
                    totalEarnings: { $sum: { $add: ['$deliveryFee', '$tip'] } },
                    averageRating: { $avg: '$rating' }
                }
            }
        ]);
        res.json(stats[0] || {
            totalDeliveries: 0,
            totalEarnings: 0,
            averageRating: 0
        });
    }
    async getEarnings(req, res) {
        const { startDate, endDate } = req.query;
        const match = {
            delivery: req.user.id,
            status: 'DELIVERED'
        };
        if (startDate && endDate) {
            match.deliveredAt = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
        }
        const earnings = await Order_1.Order.aggregate([
            { $match: match },
            {
                $group: {
                    _id: {
                        year: { $year: '$deliveredAt' },
                        month: { $month: '$deliveredAt' },
                        day: { $dayOfMonth: '$deliveredAt' }
                    },
                    earnings: { $sum: { $add: ['$deliveryFee', '$tip'] } },
                    deliveries: { $sum: 1 }
                }
            },
            { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
        ]);
        res.json(earnings);
    }
}
exports.DeliveryController = DeliveryController;
//# sourceMappingURL=deliveryController.js.map
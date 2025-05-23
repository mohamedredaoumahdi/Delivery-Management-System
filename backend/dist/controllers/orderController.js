"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderController = void 0;
const Order_1 = require("@/models/Order");
const AppError_1 = require("@/utils/AppError");
class OrderController {
    async createOrder(req, res) {
        const order = await Order_1.Order.create({
            ...req.body,
            user: req.user.id
        });
        await order.populate([
            { path: 'shop', select: 'name address' },
            { path: 'items.product', select: 'name price' }
        ]);
        res.status(201).json(order);
    }
    async getUserOrders(req, res) {
        const orders = await Order_1.Order.find({ user: req.user.id })
            .populate([
            { path: 'shop', select: 'name address' },
            { path: 'items.product', select: 'name price' }
        ])
            .sort({ createdAt: -1 });
        res.json(orders);
    }
    async getOrderById(req, res) {
        const order = await Order_1.Order.findOne({
            _id: req.params.id,
            user: req.user.id
        }).populate([
            { path: 'shop', select: 'name address' },
            { path: 'items.product', select: 'name price' },
            { path: 'delivery', select: 'name phone' }
        ]);
        if (!order) {
            throw new AppError_1.AppError('Order not found', 404);
        }
        res.json(order);
    }
    async cancelOrder(req, res) {
        const order = await Order_1.Order.findOne({
            _id: req.params.id,
            user: req.user.id
        });
        if (!order) {
            throw new AppError_1.AppError('Order not found', 404);
        }
        if (order.status !== 'PENDING') {
            throw new AppError_1.AppError('Cannot cancel order in current status', 400);
        }
        order.status = 'CANCELLED';
        await order.save();
        res.json(order);
    }
    async updateTip(req, res) {
        const { tip } = req.body;
        const order = await Order_1.Order.findOne({
            _id: req.params.id,
            user: req.user.id
        });
        if (!order) {
            throw new AppError_1.AppError('Order not found', 404);
        }
        if (order.status !== 'DELIVERED') {
            throw new AppError_1.AppError('Can only update tip for delivered orders', 400);
        }
        order.tip = tip;
        await order.save();
        res.json(order);
    }
    async trackOrder(req, res) {
        const order = await Order_1.Order.findOne({
            _id: req.params.id,
            user: req.user.id
        }).populate([
            { path: 'shop', select: 'name address location' },
            { path: 'delivery', select: 'name phone location' }
        ]);
        if (!order) {
            throw new AppError_1.AppError('Order not found', 404);
        }
        res.json({
            status: order.status,
            shop: order.shop,
            delivery: order.delivery,
            estimatedDeliveryTime: order.estimatedDeliveryTime,
            currentLocation: order.currentLocation
        });
    }
}
exports.OrderController = OrderController;
//# sourceMappingURL=orderController.js.map
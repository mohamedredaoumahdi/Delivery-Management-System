import { Request, Response } from 'express';
import { Order } from '@/models/Order';
import { AppError } from '@/utils/AppError';
import { AuthenticatedRequest } from '@/types/express';

export class OrderController {
  async createOrder(req: AuthenticatedRequest, res: Response) {
    const order = await Order.create({
      ...req.body,
      user: req.user.id
    });

    await order.populate([
      { path: 'shop', select: 'name address' },
      { path: 'items.product', select: 'name price' }
    ]);

    res.status(201).json(order);
  }

  async getUserOrders(req: AuthenticatedRequest, res: Response) {
    const orders = await Order.find({ user: req.user.id })
      .populate([
        { path: 'shop', select: 'name address' },
        { path: 'items.product', select: 'name price' }
      ])
      .sort({ createdAt: -1 });

    res.json(orders);
  }

  async getOrderById(req: AuthenticatedRequest, res: Response) {
    const order = await Order.findOne({
      _id: req.params.id,
      user: req.user.id
    }).populate([
      { path: 'shop', select: 'name address' },
      { path: 'items.product', select: 'name price' },
      { path: 'delivery', select: 'name phone' }
    ]);

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    res.json(order);
  }

  async cancelOrder(req: AuthenticatedRequest, res: Response) {
    const order = await Order.findOne({
      _id: req.params.id,
      user: req.user.id
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    if (order.status !== 'PENDING') {
      throw new AppError('Cannot cancel order in current status', 400);
    }

    order.status = 'CANCELLED';
    await order.save();

    res.json(order);
  }

  async updateTip(req: AuthenticatedRequest, res: Response) {
    const { tip } = req.body;
    const order = await Order.findOne({
      _id: req.params.id,
      user: req.user.id
    });

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    if (order.status !== 'DELIVERED') {
      throw new AppError('Can only update tip for delivered orders', 400);
    }

    order.tip = tip;
    await order.save();

    res.json(order);
  }

  async trackOrder(req: AuthenticatedRequest, res: Response) {
    const order = await Order.findOne({
      _id: req.params.id,
      user: req.user.id
    }).populate([
      { path: 'shop', select: 'name address location' },
      { path: 'delivery', select: 'name phone location' }
    ]);

    if (!order) {
      throw new AppError('Order not found', 404);
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
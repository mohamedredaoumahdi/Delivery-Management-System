import { Response } from 'express';
import { Shop } from '@/models/Shop';
import { Product } from '@/models/Product';
import { Order } from '@/models/Order';
import { AppError } from '@/utils/AppError';
import { AuthenticatedRequest } from '@/types/express';

export class VendorController {
  // Shop Management
  async getShop(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOne({ owner: req.user.id })
      .select('-__v');

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    res.json(shop);
  }

  async updateShop(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOneAndUpdate(
      { owner: req.user.id },
      { $set: req.body },
      { new: true, runValidators: true }
    ).select('-__v');

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    res.json(shop);
  }

  async updateShopStatus(req: AuthenticatedRequest, res: Response) {
    const { status } = req.body;
    const shop = await Shop.findOneAndUpdate(
      { owner: req.user.id },
      { $set: { status } },
      { new: true, runValidators: true }
    ).select('-__v');

    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    res.json(shop);
  }

  // Product Management
  async getProducts(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const products = await Product.find({ shop: shop._id })
      .select('-__v')
      .sort({ createdAt: -1 });

    res.json(products);
  }

  async createProduct(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const product = await Product.create({
      ...req.body,
      shop: shop._id
    });

    res.status(201).json(product);
  }

  async updateProduct(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const product = await Product.findOneAndUpdate(
      { _id: req.params.id, shop: shop._id },
      { $set: req.body },
      { new: true, runValidators: true }
    ).select('-__v');

    if (!product) {
      throw new AppError('Product not found', 404);
    }

    res.json(product);
  }

  async deleteProduct(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const product = await Product.findOneAndDelete({
      _id: req.params.id,
      shop: shop._id
    });

    if (!product) {
      throw new AppError('Product not found', 404);
    }

    res.status(204).send();
  }

  // Order Management
  async getOrders(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const orders = await Order.find({ shop: shop._id })
      .populate([
        { path: 'user', select: 'name phone address' },
        { path: 'delivery', select: 'name phone' }
      ])
      .sort({ createdAt: -1 });

    res.json(orders);
  }

  async updateOrderStatus(req: AuthenticatedRequest, res: Response) {
    const { status } = req.body;
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const order = await Order.findOneAndUpdate(
      { _id: req.params.id, shop: shop._id },
      { $set: { status } },
      { new: true, runValidators: true }
    );

    if (!order) {
      throw new AppError('Order not found', 404);
    }

    res.json(order);
  }

  async getOrderStats(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const stats = await Order.aggregate([
      {
        $match: {
          shop: shop._id,
          status: 'DELIVERED'
        }
      },
      {
        $group: {
          _id: null,
          totalOrders: { $sum: 1 },
          totalRevenue: { $sum: '$total' },
          averageOrderValue: { $avg: '$total' }
        }
      }
    ]);

    res.json(stats[0] || {
      totalOrders: 0,
      totalRevenue: 0,
      averageOrderValue: 0
    });
  }

  // Analytics
  async getSalesAnalytics(req: AuthenticatedRequest, res: Response) {
    const { startDate, endDate } = req.query;
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const match: any = {
      shop: shop._id,
      status: 'DELIVERED'
    };

    if (startDate && endDate) {
      match.deliveredAt = {
        $gte: new Date(startDate as string),
        $lte: new Date(endDate as string)
      };
    }

    const sales = await Order.aggregate([
      { $match: match },
      {
        $group: {
          _id: {
            year: { $year: '$deliveredAt' },
            month: { $month: '$deliveredAt' },
            day: { $dayOfMonth: '$deliveredAt' }
          },
          revenue: { $sum: '$total' },
          orders: { $sum: 1 }
        }
      },
      { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
    ]);

    res.json(sales);
  }

  async getProductAnalytics(req: AuthenticatedRequest, res: Response) {
    const shop = await Shop.findOne({ owner: req.user.id });
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    const products = await Order.aggregate([
      {
        $match: {
          shop: shop._id,
          status: 'DELIVERED'
        }
      },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.product',
          totalSold: { $sum: '$items.quantity' },
          revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } }
        }
      },
      {
        $lookup: {
          from: 'products',
          localField: '_id',
          foreignField: '_id',
          as: 'product'
        }
      },
      { $unwind: '$product' },
      {
        $project: {
          _id: 1,
          name: '$product.name',
          totalSold: 1,
          revenue: 1
        }
      },
      { $sort: { totalSold: -1 } }
    ]);

    res.json(products);
  }
} 
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VendorController = void 0;
const Shop_1 = require("@/models/Shop");
const Product_1 = require("@/models/Product");
const Order_1 = require("@/models/Order");
const AppError_1 = require("@/utils/AppError");
class VendorController {
    async getShop(req, res) {
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id })
            .select('-__v');
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        res.json(shop);
    }
    async updateShop(req, res) {
        const shop = await Shop_1.Shop.findOneAndUpdate({ owner: req.user.id }, { $set: req.body }, { new: true, runValidators: true }).select('-__v');
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        res.json(shop);
    }
    async updateShopStatus(req, res) {
        const { status } = req.body;
        const shop = await Shop_1.Shop.findOneAndUpdate({ owner: req.user.id }, { $set: { status } }, { new: true, runValidators: true }).select('-__v');
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        res.json(shop);
    }
    async getProducts(req, res) {
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const products = await Product_1.Product.find({ shop: shop._id })
            .select('-__v')
            .sort({ createdAt: -1 });
        res.json(products);
    }
    async createProduct(req, res) {
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const product = await Product_1.Product.create({
            ...req.body,
            shop: shop._id
        });
        res.status(201).json(product);
    }
    async updateProduct(req, res) {
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const product = await Product_1.Product.findOneAndUpdate({ _id: req.params.id, shop: shop._id }, { $set: req.body }, { new: true, runValidators: true }).select('-__v');
        if (!product) {
            throw new AppError_1.AppError('Product not found', 404);
        }
        res.json(product);
    }
    async deleteProduct(req, res) {
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const product = await Product_1.Product.findOneAndDelete({
            _id: req.params.id,
            shop: shop._id
        });
        if (!product) {
            throw new AppError_1.AppError('Product not found', 404);
        }
        res.status(204).send();
    }
    async getOrders(req, res) {
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const orders = await Order_1.Order.find({ shop: shop._id })
            .populate([
            { path: 'user', select: 'name phone address' },
            { path: 'delivery', select: 'name phone' }
        ])
            .sort({ createdAt: -1 });
        res.json(orders);
    }
    async updateOrderStatus(req, res) {
        const { status } = req.body;
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const order = await Order_1.Order.findOneAndUpdate({ _id: req.params.id, shop: shop._id }, { $set: { status } }, { new: true, runValidators: true });
        if (!order) {
            throw new AppError_1.AppError('Order not found', 404);
        }
        res.json(order);
    }
    async getOrderStats(req, res) {
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const stats = await Order_1.Order.aggregate([
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
    async getSalesAnalytics(req, res) {
        const { startDate, endDate } = req.query;
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const match = {
            shop: shop._id,
            status: 'DELIVERED'
        };
        if (startDate && endDate) {
            match.deliveredAt = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
        }
        const sales = await Order_1.Order.aggregate([
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
    async getProductAnalytics(req, res) {
        const shop = await Shop_1.Shop.findOne({ owner: req.user.id });
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        const products = await Order_1.Order.aggregate([
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
exports.VendorController = VendorController;
//# sourceMappingURL=vendorController.js.map
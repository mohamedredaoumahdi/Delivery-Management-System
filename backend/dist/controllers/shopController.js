"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ShopController = void 0;
const Shop_1 = require("@/models/Shop");
const Product_1 = require("@/models/Product");
const Category_1 = require("@/models/Category");
const AppError_1 = require("@/utils/AppError");
class ShopController {
    async getShops(req, res) {
        const shops = await Shop_1.Shop.find({ status: 'ACTIVE' })
            .select('-__v')
            .sort({ rating: -1 });
        res.json(shops);
    }
    async getFeaturedShops(req, res) {
        const shops = await Shop_1.Shop.find({
            status: 'ACTIVE',
            isFeatured: true
        })
            .select('-__v')
            .sort({ rating: -1 })
            .limit(10);
        res.json(shops);
    }
    async getNearbyShops(req, res) {
        const { lat, lng, radius = 5 } = req.query;
        if (!lat || !lng) {
            throw new AppError_1.AppError('Location coordinates are required', 400);
        }
        const shops = await Shop_1.Shop.find({
            status: 'ACTIVE',
            location: {
                $near: {
                    $geometry: {
                        type: 'Point',
                        coordinates: [parseFloat(lng), parseFloat(lat)]
                    },
                    $maxDistance: parseFloat(radius) * 1000
                }
            }
        })
            .select('-__v')
            .limit(20);
        res.json(shops);
    }
    async getShopById(req, res) {
        const shop = await Shop_1.Shop.findById(req.params.id)
            .select('-__v');
        if (!shop) {
            throw new AppError_1.AppError('Shop not found', 404);
        }
        res.json(shop);
    }
    async getShopProducts(req, res) {
        const products = await Product_1.Product.find({
            shop: req.params.id,
            status: 'ACTIVE'
        })
            .select('-__v')
            .sort({ createdAt: -1 });
        res.json(products);
    }
    async getShopCategories(req, res) {
        const categories = await Category_1.Category.find({
            shop: req.params.id,
            status: 'ACTIVE'
        })
            .select('-__v')
            .sort({ name: 1 });
        res.json(categories);
    }
}
exports.ShopController = ShopController;
//# sourceMappingURL=shopController.js.map
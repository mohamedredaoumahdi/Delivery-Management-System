"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProductController = void 0;
const database_1 = require("@/config/database");
const appError_1 = require("@/utils/appError");
const catchAsync_1 = require("@/utils/catchAsync");
class ProductController {
    getProducts = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const products = await database_1.prisma.product.findMany({
            include: {
                shop: true,
                category: true,
            },
        });
        res.json({
            status: 'success',
            data: products,
        });
    });
    getProductById = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const product = await database_1.prisma.product.findUnique({
            where: { id: req.params.id },
            include: {
                shop: true,
                category: true,
            },
        });
        if (!product) {
            return next(new appError_1.AppError('Product not found', 404));
        }
        res.json({
            status: 'success',
            data: product,
        });
    });
    getProductsByCategory = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const products = await database_1.prisma.product.findMany({
            where: { categoryId: req.params.categoryId },
            include: {
                shop: true,
                category: true,
            },
        });
        res.json({
            status: 'success',
            data: products,
        });
    });
    getProductsByShop = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const products = await database_1.prisma.product.findMany({
            where: { shopId: req.params.shopId },
            include: {
                category: true,
            },
        });
        res.json({
            status: 'success',
            data: products,
        });
    });
    createProduct = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { name, description, price, categoryId, shopId } = req.body;
        const images = req.body.images || [];
        const category = await database_1.prisma.category.findUnique({ where: { id: categoryId } });
        if (!category)
            throw new appError_1.AppError('Category not found', 404);
        const product = await database_1.prisma.product.create({
            data: {
                name,
                description,
                price: parseFloat(price),
                categoryId,
                shopId,
                images,
                categoryName: category.name,
            },
        });
        res.status(201).json({
            status: 'success',
            data: product,
        });
    });
    updateProduct = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { name, description, price, categoryId, tags, nutritionalInfo, inStock, stockQuantity } = req.body;
        const images = req.files?.map(file => file.path);
        const product = await database_1.prisma.product.update({
            where: { id: req.params.id },
            data: {
                name,
                description,
                price: price ? parseFloat(price) : undefined,
                categoryId,
                images: images ? { set: images } : undefined,
                tags: tags ? { set: tags } : undefined,
                nutritionalInfo: nutritionalInfo ? nutritionalInfo : undefined,
                inStock,
                stockQuantity,
                updatedAt: new Date()
            },
        });
        res.json({
            status: 'success',
            data: product,
        });
    });
    deleteProduct = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        await database_1.prisma.product.delete({
            where: { id: req.params.id },
        });
        res.json({
            status: 'success',
            data: null,
        });
    });
    updateProductStatus = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { isActive } = req.body;
        const product = await database_1.prisma.product.update({
            where: { id: req.params.id },
            data: { isActive },
        });
        res.json({
            status: 'success',
            data: product,
        });
    });
}
exports.ProductController = ProductController;
//# sourceMappingURL=productController.js.map
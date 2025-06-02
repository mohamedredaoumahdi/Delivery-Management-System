"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminController = void 0;
const database_1 = require("@/config/database");
const appError_1 = require("@/utils/appError");
const catchAsync_1 = require("@/utils/catchAsync");
const config_1 = require("@/config/config");
const path_1 = __importDefault(require("path"));
const uuid_1 = require("uuid");
const sharp_1 = __importDefault(require("sharp"));
const promises_1 = __importDefault(require("fs/promises"));
class AdminController {
    getUsers = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const users = await database_1.prisma.user.findMany();
        res.json({ status: 'success', data: users });
    });
    getUserById = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const user = await database_1.prisma.user.findUnique({ where: { id: req.params.id } });
        if (!user)
            return next(new appError_1.AppError('User not found', 404));
        res.json({ status: 'success', data: user });
    });
    updateUser = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const user = await database_1.prisma.user.update({
            where: { id: req.params.id },
            data: req.body,
        });
        res.json({ status: 'success', data: user });
    });
    deleteUser = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        await database_1.prisma.user.delete({ where: { id: req.params.id } });
        res.json({ status: 'success', data: null });
    });
    getShops = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const shops = await database_1.prisma.shop.findMany();
        res.json({ status: 'success', data: shops });
    });
    createShop = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { categoryId, ...rest } = req.body;
        const shop = await database_1.prisma.shop.create({
            data: {
                ...rest,
                category: rest.category,
            },
        });
        res.status(201).json({ status: 'success', data: shop });
    });
    updateShop = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const shop = await database_1.prisma.shop.update({
            where: { id: req.params.id },
            data: req.body,
        });
        res.json({ status: 'success', data: shop });
    });
    deleteShop = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        await database_1.prisma.shop.delete({ where: { id: req.params.id } });
        res.json({ status: 'success', data: null });
    });
    getCategories = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const categories = await database_1.prisma.category.findMany();
        res.json({ status: 'success', data: categories });
    });
    createCategory = (0, catchAsync_1.catchAsync)(async (req, res) => {
        if (!req.file) {
            throw new appError_1.AppError('Image is required', 400);
        }
        const { shopId, ...rest } = req.body;
        if (!shopId) {
            throw new appError_1.AppError('shopId is required', 400);
        }
        const filename = `category-${Date.now()}-${(0, uuid_1.v4)()}.jpeg`;
        const filepath = path_1.default.join(config_1.config.uploadDir, filename);
        await promises_1.default.mkdir(config_1.config.uploadDir, { recursive: true });
        await (0, sharp_1.default)(req.file.buffer)
            .resize(800, 600)
            .toFormat('jpeg')
            .jpeg({ quality: 90 })
            .toFile(filepath);
        const category = await database_1.prisma.category.create({
            data: {
                ...rest,
                shopId,
                imageUrl: `/uploads/${filename}`,
            },
        });
        res.status(201).json({ status: 'success', data: category });
    });
    updateCategory = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const data = { ...req.body };
        if (req.file) {
            const filename = `category-${Date.now()}-${(0, uuid_1.v4)()}.jpeg`;
            const filepath = path_1.default.join(config_1.config.uploadDir, filename);
            await promises_1.default.mkdir(config_1.config.uploadDir, { recursive: true });
            await (0, sharp_1.default)(req.file.buffer)
                .resize(800, 600)
                .toFormat('jpeg')
                .jpeg({ quality: 90 })
                .toFile(filepath);
            data.imageUrl = `/uploads/${filename}`;
        }
        const category = await database_1.prisma.category.update({
            where: { id: req.params.id },
            data,
        });
        res.json({ status: 'success', data: category });
    });
    deleteCategory = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        await database_1.prisma.category.delete({ where: { id: req.params.id } });
        res.json({ status: 'success', data: null });
    });
    getUserAnalytics = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const analytics = await database_1.prisma.user.groupBy({
            by: ['role'],
            _count: true,
        });
        res.json({ status: 'success', data: analytics });
    });
    getOrderAnalytics = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const analytics = await database_1.prisma.order.groupBy({
            by: ['status'],
            _count: true,
            _sum: { total: true },
        });
        res.json({ status: 'success', data: analytics });
    });
    getRevenueAnalytics = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const analytics = await database_1.prisma.order.aggregate({
            _sum: { total: true },
            _avg: { total: true },
        });
        res.json({ status: 'success', data: analytics });
    });
}
exports.AdminController = AdminController;
//# sourceMappingURL=adminController.js.map
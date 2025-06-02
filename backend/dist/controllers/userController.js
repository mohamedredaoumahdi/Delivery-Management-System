"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserController = void 0;
const database_1 = require("@/config/database");
const appError_1 = require("@/utils/appError");
const catchAsync_1 = require("@/utils/catchAsync");
const bcrypt_1 = __importDefault(require("bcrypt"));
class UserController {
    getProfile = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const user = await database_1.prisma.user.findUnique({
            where: { id: req.user.id },
            select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                profilePicture: true,
                role: true,
                isEmailVerified: true,
                isPhoneVerified: true,
                createdAt: true,
                updatedAt: true,
            },
        });
        res.json({ status: 'success', data: user });
    });
    updateProfile = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { name, phone } = req.body;
        const user = await database_1.prisma.user.update({
            where: { id: req.user.id },
            data: { name, phone },
            select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                profilePicture: true,
                role: true,
                isEmailVerified: true,
                isPhoneVerified: true,
                createdAt: true,
                updatedAt: true,
            },
        });
        res.json({ status: 'success', data: user });
    });
    changePassword = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { currentPassword, newPassword } = req.body;
        const user = await database_1.prisma.user.findUnique({
            where: { id: req.user.id },
            select: {
                id: true,
                passwordHash: true,
            },
        });
        if (!user || !(await bcrypt_1.default.compare(currentPassword, user.passwordHash))) {
            throw new appError_1.AppError('Current password is incorrect', 401);
        }
        const hashedPassword = await bcrypt_1.default.hash(newPassword, 10);
        await database_1.prisma.user.update({
            where: { id: req.user.id },
            data: { passwordHash: hashedPassword },
        });
        res.json({ status: 'success', message: 'Password updated successfully' });
    });
    getAddresses = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const addresses = await database_1.prisma.address.findMany({
            where: { userId: req.user.id },
            orderBy: { isDefault: 'desc' },
        });
        res.json({ status: 'success', data: addresses });
    });
    addAddress = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { label, fullAddress, latitude, longitude, instructions, isDefault } = req.body;
        if (isDefault) {
            await database_1.prisma.address.updateMany({
                where: { userId: req.user.id },
                data: { isDefault: false },
            });
        }
        const address = await database_1.prisma.address.create({
            data: {
                label,
                fullAddress,
                latitude,
                longitude,
                instructions,
                isDefault,
                userId: req.user.id,
            },
        });
        res.status(201).json({ status: 'success', data: address });
    });
    updateAddress = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { id } = req.params;
        const { label, fullAddress, latitude, longitude, instructions, isDefault } = req.body;
        if (isDefault) {
            await database_1.prisma.address.updateMany({
                where: { userId: req.user.id },
                data: { isDefault: false },
            });
        }
        const address = await database_1.prisma.address.update({
            where: { id, userId: req.user.id },
            data: {
                label,
                fullAddress,
                latitude,
                longitude,
                instructions,
                isDefault,
            },
        });
        res.json({ status: 'success', data: address });
    });
    deleteAddress = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { id } = req.params;
        await database_1.prisma.address.delete({
            where: { id, userId: req.user.id },
        });
        res.json({ status: 'success', message: 'Address deleted successfully' });
    });
    setDefaultAddress = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { id } = req.params;
        await database_1.prisma.address.updateMany({
            where: { userId: req.user.id },
            data: { isDefault: false },
        });
        const address = await database_1.prisma.address.update({
            where: { id, userId: req.user.id },
            data: { isDefault: true },
        });
        res.json({ status: 'success', data: address });
    });
    getOrderHistory = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const orders = await database_1.prisma.order.findMany({
            where: { userId: req.user.id },
            include: {
                items: {
                    include: {
                        product: true,
                    },
                },
                shop: true,
            },
            orderBy: { createdAt: 'desc' },
        });
        res.json({ status: 'success', data: orders });
    });
    getOrderDetails = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { id } = req.params;
        const order = await database_1.prisma.order.findUnique({
            where: { id, userId: req.user.id },
            include: {
                items: {
                    include: {
                        product: true,
                    },
                },
                shop: true,
                deliveryPerson: true,
            },
        });
        if (!order) {
            throw new appError_1.AppError('Order not found', 404);
        }
        res.json({ status: 'success', data: order });
    });
    getFavorites = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const favorites = await database_1.prisma.userFavorite.findMany({
            where: { userId: req.user.id },
            include: { shop: true },
        });
        res.json({ status: 'success', data: favorites });
    });
    addToFavorites = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { shopId } = req.params;
        const favorite = await database_1.prisma.userFavorite.create({
            data: {
                userId: req.user.id,
                shopId,
            },
            include: { shop: true },
        });
        res.status(201).json({ status: 'success', data: favorite });
    });
    removeFromFavorites = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const { shopId } = req.params;
        await database_1.prisma.userFavorite.delete({
            where: {
                userId_shopId: {
                    userId: req.user.id,
                    shopId,
                },
            },
        });
        res.json({ status: 'success', message: 'Removed from favorites' });
    });
}
exports.UserController = UserController;
//# sourceMappingURL=userController.js.map
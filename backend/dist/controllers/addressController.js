"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddressController = void 0;
const database_1 = require("@/config/database");
const catchAsync_1 = require("@/utils/catchAsync");
class AddressController {
    getAddresses = (0, catchAsync_1.catchAsync)(async (req, res) => {
        const addresses = await database_1.prisma.address.findMany({
            where: { userId: req.user.id },
        });
        res.json({
            status: 'success',
            data: addresses,
        });
    });
    createAddress = (0, catchAsync_1.catchAsync)(async (req, res) => {
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
        res.status(201).json({
            status: 'success',
            data: address,
        });
    });
    updateAddress = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        const { label, fullAddress, latitude, longitude, instructions, isDefault } = req.body;
        if (isDefault) {
            await database_1.prisma.address.updateMany({
                where: { userId: req.user.id },
                data: { isDefault: false },
            });
        }
        const address = await database_1.prisma.address.update({
            where: { id: req.params.id },
            data: {
                label,
                fullAddress,
                latitude,
                longitude,
                instructions,
                isDefault,
            },
        });
        res.json({
            status: 'success',
            data: address,
        });
    });
    deleteAddress = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        await database_1.prisma.address.delete({
            where: { id: req.params.id },
        });
        res.json({
            status: 'success',
            data: null,
        });
    });
    setDefaultAddress = (0, catchAsync_1.catchAsync)(async (req, res, next) => {
        await database_1.prisma.address.updateMany({
            where: { userId: req.user.id },
            data: { isDefault: false },
        });
        const address = await database_1.prisma.address.update({
            where: { id: req.params.id },
            data: { isDefault: true },
        });
        res.json({
            status: 'success',
            data: address,
        });
    });
}
exports.AddressController = AddressController;
//# sourceMappingURL=addressController.js.map
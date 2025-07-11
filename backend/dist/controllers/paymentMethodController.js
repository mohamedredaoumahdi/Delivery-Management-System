"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentMethodController = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const logger_1 = require("@/utils/logger");
const prisma = new client_1.PrismaClient();
class PaymentMethodController {
    async getPaymentMethods(req, res) {
        logger_1.logger.info('💳 PaymentMethodController: Getting user payment methods');
        const userId = req.user.id;
        const paymentMethods = await prisma.userPaymentMethod.findMany({
            where: {
                userId,
                isActive: true
            },
            orderBy: [
                { isDefault: 'desc' },
                { createdAt: 'desc' }
            ]
        });
        logger_1.logger.info(`💳 ✅ PaymentMethodController: Successfully fetched ${paymentMethods.length} payment methods`);
        res.json({
            status: 'success',
            data: paymentMethods
        });
    }
    async createPaymentMethod(req, res) {
        logger_1.logger.info('💳 PaymentMethodController: Creating new payment method');
        const userId = req.user.id;
        const { type, label, cardLast4, cardBrand, cardExpiryMonth, cardExpiryYear, cardHolderName, walletEmail, walletProvider, bankName, bankAccountLast4, isDefault = false } = req.body;
        if (isDefault) {
            await prisma.userPaymentMethod.updateMany({
                where: { userId, isDefault: true },
                data: { isDefault: false }
            });
        }
        const existingCount = await prisma.userPaymentMethod.count({
            where: { userId, isActive: true }
        });
        const shouldBeDefault = isDefault || existingCount === 0;
        const paymentMethod = await prisma.userPaymentMethod.create({
            data: {
                type,
                label,
                cardLast4,
                cardBrand,
                cardExpiryMonth,
                cardExpiryYear,
                cardHolderName,
                walletEmail,
                walletProvider,
                bankName,
                bankAccountLast4,
                isDefault: shouldBeDefault,
                userId
            }
        });
        logger_1.logger.info(`💳 ✅ PaymentMethodController: Successfully created payment method ${paymentMethod.id}`);
        res.status(201).json({
            status: 'success',
            data: paymentMethod
        });
    }
    async updatePaymentMethod(req, res) {
        logger_1.logger.info('💳 PaymentMethodController: Updating payment method');
        const userId = req.user.id;
        const { paymentMethodId } = req.params;
        const { label, cardExpiryMonth, cardExpiryYear, cardHolderName, walletEmail, bankName, isDefault } = req.body;
        const existingPaymentMethod = await prisma.userPaymentMethod.findFirst({
            where: {
                id: paymentMethodId,
                userId,
                isActive: true
            }
        });
        if (!existingPaymentMethod) {
            throw new appError_1.AppError('Payment method not found', 404);
        }
        if (isDefault) {
            await prisma.userPaymentMethod.updateMany({
                where: { userId, isDefault: true },
                data: { isDefault: false }
            });
        }
        const updatedPaymentMethod = await prisma.userPaymentMethod.update({
            where: { id: paymentMethodId },
            data: {
                label,
                cardExpiryMonth,
                cardExpiryYear,
                cardHolderName,
                walletEmail,
                bankName,
                isDefault
            }
        });
        logger_1.logger.info(`💳 ✅ PaymentMethodController: Successfully updated payment method ${paymentMethodId}`);
        res.json({
            status: 'success',
            data: updatedPaymentMethod
        });
    }
    async deletePaymentMethod(req, res) {
        logger_1.logger.info('💳 PaymentMethodController: Deleting payment method');
        const userId = req.user.id;
        const { paymentMethodId } = req.params;
        const existingPaymentMethod = await prisma.userPaymentMethod.findFirst({
            where: {
                id: paymentMethodId,
                userId,
                isActive: true
            }
        });
        if (!existingPaymentMethod) {
            throw new appError_1.AppError('Payment method not found', 404);
        }
        await prisma.userPaymentMethod.update({
            where: { id: paymentMethodId },
            data: { isActive: false }
        });
        if (existingPaymentMethod.isDefault) {
            const nextPaymentMethod = await prisma.userPaymentMethod.findFirst({
                where: {
                    userId,
                    isActive: true,
                    id: { not: paymentMethodId }
                },
                orderBy: { createdAt: 'desc' }
            });
            if (nextPaymentMethod) {
                await prisma.userPaymentMethod.update({
                    where: { id: nextPaymentMethod.id },
                    data: { isDefault: true }
                });
            }
        }
        logger_1.logger.info(`💳 ✅ PaymentMethodController: Successfully deleted payment method ${paymentMethodId}`);
        res.json({
            status: 'success',
            message: 'Payment method deleted successfully'
        });
    }
    async setDefaultPaymentMethod(req, res) {
        logger_1.logger.info('💳 PaymentMethodController: Setting default payment method');
        const userId = req.user.id;
        const { paymentMethodId } = req.params;
        const existingPaymentMethod = await prisma.userPaymentMethod.findFirst({
            where: {
                id: paymentMethodId,
                userId,
                isActive: true
            }
        });
        if (!existingPaymentMethod) {
            throw new appError_1.AppError('Payment method not found', 404);
        }
        await prisma.userPaymentMethod.updateMany({
            where: { userId, isDefault: true },
            data: { isDefault: false }
        });
        const updatedPaymentMethod = await prisma.userPaymentMethod.update({
            where: { id: paymentMethodId },
            data: { isDefault: true }
        });
        logger_1.logger.info(`💳 ✅ PaymentMethodController: Successfully set payment method ${paymentMethodId} as default`);
        res.json({
            status: 'success',
            data: updatedPaymentMethod
        });
    }
}
exports.PaymentMethodController = PaymentMethodController;
//# sourceMappingURL=paymentMethodController.js.map
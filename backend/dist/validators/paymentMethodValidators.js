"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.paymentMethodIdSchema = exports.updatePaymentMethodSchema = exports.createPaymentMethodSchema = void 0;
const joi_1 = __importDefault(require("joi"));
const client_1 = require("@prisma/client");
exports.createPaymentMethodSchema = joi_1.default.object({
    type: joi_1.default.string().valid(...Object.values(client_1.PaymentMethodType)).required(),
    label: joi_1.default.string().min(1).max(50).required(),
    cardLast4: joi_1.default.when('type', {
        is: joi_1.default.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
        then: joi_1.default.string().length(4).pattern(/^\d{4}$/).required(),
        otherwise: joi_1.default.string().optional()
    }),
    cardBrand: joi_1.default.when('type', {
        is: joi_1.default.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
        then: joi_1.default.string().valid('visa', 'mastercard', 'amex', 'discover', 'other').required(),
        otherwise: joi_1.default.string().optional()
    }),
    cardExpiryMonth: joi_1.default.when('type', {
        is: joi_1.default.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
        then: joi_1.default.number().integer().min(1).max(12).required(),
        otherwise: joi_1.default.number().optional()
    }),
    cardExpiryYear: joi_1.default.when('type', {
        is: joi_1.default.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
        then: joi_1.default.number().integer().min(new Date().getFullYear()).max(new Date().getFullYear() + 20).required(),
        otherwise: joi_1.default.number().optional()
    }),
    cardHolderName: joi_1.default.when('type', {
        is: joi_1.default.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
        then: joi_1.default.string().min(2).max(100).required(),
        otherwise: joi_1.default.string().optional()
    }),
    walletEmail: joi_1.default.when('type', {
        is: joi_1.default.string().valid('PAYPAL'),
        then: joi_1.default.string().email().required(),
        otherwise: joi_1.default.string().email().optional()
    }),
    walletProvider: joi_1.default.when('type', {
        is: joi_1.default.string().valid('PAYPAL', 'APPLE_PAY', 'GOOGLE_PAY'),
        then: joi_1.default.string().valid('paypal', 'apple_pay', 'google_pay').required(),
        otherwise: joi_1.default.string().optional()
    }),
    bankName: joi_1.default.when('type', {
        is: joi_1.default.string().valid('BANK_ACCOUNT'),
        then: joi_1.default.string().min(2).max(100).required(),
        otherwise: joi_1.default.string().optional()
    }),
    bankAccountLast4: joi_1.default.when('type', {
        is: joi_1.default.string().valid('BANK_ACCOUNT'),
        then: joi_1.default.string().length(4).pattern(/^\d{4}$/).required(),
        otherwise: joi_1.default.string().optional()
    }),
    isDefault: joi_1.default.boolean().optional()
});
exports.updatePaymentMethodSchema = joi_1.default.object({
    label: joi_1.default.string().min(1).max(50).optional(),
    cardExpiryMonth: joi_1.default.number().integer().min(1).max(12).optional(),
    cardExpiryYear: joi_1.default.number().integer().min(new Date().getFullYear()).max(new Date().getFullYear() + 20).optional(),
    cardHolderName: joi_1.default.string().min(2).max(100).optional(),
    walletEmail: joi_1.default.string().email().optional(),
    bankName: joi_1.default.string().min(2).max(100).optional(),
    isDefault: joi_1.default.boolean().optional()
});
exports.paymentMethodIdSchema = joi_1.default.object({
    paymentMethodId: joi_1.default.string().uuid().required()
});
//# sourceMappingURL=paymentMethodValidators.js.map
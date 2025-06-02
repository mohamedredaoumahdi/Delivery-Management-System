"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateOrderStatusSchema = exports.cancelOrderSchema = exports.updateOrderSchema = exports.createOrderSchema = void 0;
const joi_1 = __importDefault(require("joi"));
const client_1 = require("@prisma/client");
exports.createOrderSchema = joi_1.default.object({
    shopId: joi_1.default.string().required(),
    items: joi_1.default.array().items(joi_1.default.object({
        productId: joi_1.default.string().required(),
        productName: joi_1.default.string().required(),
        productPrice: joi_1.default.number().positive().required(),
        quantity: joi_1.default.number().integer().min(1).required(),
        totalPrice: joi_1.default.number().positive().required(),
        instructions: joi_1.default.string().optional().allow(''),
    })).required(),
    deliveryAddress: joi_1.default.string().required(),
    deliveryLatitude: joi_1.default.number().optional(),
    deliveryLongitude: joi_1.default.number().optional(),
    deliveryInstructions: joi_1.default.string().optional().allow(''),
    paymentMethod: joi_1.default.string().valid(...Object.values(client_1.PaymentMethod)).required(),
    tip: joi_1.default.number().min(0).optional().default(0),
});
exports.updateOrderSchema = joi_1.default.object({
    tip: joi_1.default.number().min(0).required(),
});
exports.cancelOrderSchema = joi_1.default.object({
    reason: joi_1.default.string().optional(),
});
exports.updateOrderStatusSchema = joi_1.default.object({
    status: joi_1.default.string().required(),
    rejectionReason: joi_1.default.string().optional(),
    estimatedDeliveryTime: joi_1.default.date().optional(),
});
//# sourceMappingURL=orderValidators.js.map
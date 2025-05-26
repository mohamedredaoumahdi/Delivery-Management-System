"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateOrderSchema = exports.createOrderSchema = void 0;
const joi_1 = __importDefault(require("joi"));
exports.createOrderSchema = joi_1.default.object({
    shopId: joi_1.default.string().required(),
    items: joi_1.default.array().items(joi_1.default.object({
        productId: joi_1.default.string().required(),
        quantity: joi_1.default.number().integer().min(1).required(),
        instructions: joi_1.default.string().optional(),
    })).required(),
    deliveryAddress: joi_1.default.string().required(),
    paymentMethod: joi_1.default.string().valid('CASH', 'CARD').required(),
});
exports.updateOrderSchema = joi_1.default.object({
    tip: joi_1.default.number().min(0).required(),
});
//# sourceMappingURL=orderValidators.js.map
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateProductSchema = exports.createProductSchema = void 0;
const joi_1 = __importDefault(require("joi"));
exports.createProductSchema = joi_1.default.object({
    name: joi_1.default.string().required().min(3).max(100),
    description: joi_1.default.string().required().min(10).max(1000),
    price: joi_1.default.number().required().min(0),
    categoryId: joi_1.default.string().required(),
});
exports.updateProductSchema = joi_1.default.object({
    name: joi_1.default.string().min(3).max(100),
    description: joi_1.default.string().min(10).max(1000),
    price: joi_1.default.number().min(0),
    categoryId: joi_1.default.string(),
    inStock: joi_1.default.boolean(),
    stockQuantity: joi_1.default.number().min(0)
});
//# sourceMappingURL=productValidators.js.map
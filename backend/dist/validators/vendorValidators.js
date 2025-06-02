"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createProductSchema = exports.updateShopSchema = void 0;
const joi_1 = __importDefault(require("joi"));
exports.updateShopSchema = joi_1.default.object({
    name: joi_1.default.string().min(2).max(100),
    description: joi_1.default.string().min(10).max(500),
    address: joi_1.default.string().min(5).max(200),
    latitude: joi_1.default.number().min(-90).max(90),
    longitude: joi_1.default.number().min(-180).max(180),
    phone: joi_1.default.string().pattern(/^\+?[\d\s-]{10,}$/),
    email: joi_1.default.string().email(),
    openingHours: joi_1.default.string(),
    categoryId: joi_1.default.string(),
    isActive: joi_1.default.boolean(),
});
exports.createProductSchema = joi_1.default.object({
    name: joi_1.default.string().required().min(2).max(100),
    description: joi_1.default.string().required().min(10).max(500),
    price: joi_1.default.number().required().min(0),
    categoryId: joi_1.default.string().required(),
    isAvailable: joi_1.default.boolean(),
    preparationTime: joi_1.default.number().min(0),
});
//# sourceMappingURL=vendorValidators.js.map
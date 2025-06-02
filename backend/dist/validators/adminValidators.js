"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateCategorySchema = exports.createCategorySchema = exports.updateShopSchema = exports.createShopSchema = exports.updateUserSchema = void 0;
const joi_1 = __importDefault(require("joi"));
exports.updateUserSchema = joi_1.default.object({
    name: joi_1.default.string().min(2).max(50),
    email: joi_1.default.string().email(),
    role: joi_1.default.string().valid('USER', 'VENDOR', 'DELIVERY', 'ADMIN'),
    isActive: joi_1.default.boolean(),
});
exports.createShopSchema = joi_1.default.object({
    name: joi_1.default.string().required().min(2).max(100),
    description: joi_1.default.string().required().min(10).max(500),
    address: joi_1.default.string().required().min(5).max(200),
    latitude: joi_1.default.number().required().min(-90).max(90),
    longitude: joi_1.default.number().required().min(-180).max(180),
    phone: joi_1.default.string().required().pattern(/^\+?[\d\s-]{10,}$/),
    email: joi_1.default.string().required().email(),
    openingHours: joi_1.default.string().required(),
    category: joi_1.default.string().valid('RESTAURANT', 'GROCERY', 'PHARMACY', 'RETAIL', 'OTHER').required(),
    estimatedDeliveryTime: joi_1.default.number().required().min(0),
    ownerId: joi_1.default.string().required(),
    website: joi_1.default.string().uri().allow(''),
    hasDelivery: joi_1.default.boolean(),
    hasPickup: joi_1.default.boolean(),
    minimumOrderAmount: joi_1.default.number().min(0),
    deliveryFee: joi_1.default.number().min(0),
});
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
exports.createCategorySchema = joi_1.default.object({
    name: joi_1.default.string().required().min(2).max(50),
    description: joi_1.default.string().required().min(10).max(200),
});
exports.updateCategorySchema = joi_1.default.object({
    name: joi_1.default.string().min(2).max(50),
    description: joi_1.default.string().min(10).max(200),
    isActive: joi_1.default.boolean(),
});
//# sourceMappingURL=adminValidators.js.map
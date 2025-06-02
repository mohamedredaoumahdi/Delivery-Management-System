"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateAddressSchema = exports.createAddressSchema = void 0;
const joi_1 = __importDefault(require("joi"));
exports.createAddressSchema = joi_1.default.object({
    label: joi_1.default.string().required().min(2).max(50),
    fullAddress: joi_1.default.string().required().min(5).max(200),
    latitude: joi_1.default.number().required().min(-90).max(90),
    longitude: joi_1.default.number().required().min(-180).max(180),
    instructions: joi_1.default.string().max(200),
    isDefault: joi_1.default.boolean(),
});
exports.updateAddressSchema = joi_1.default.object({
    label: joi_1.default.string().min(2).max(50),
    fullAddress: joi_1.default.string().min(5).max(200),
    latitude: joi_1.default.number().min(-90).max(90),
    longitude: joi_1.default.number().min(-180).max(180),
    instructions: joi_1.default.string().max(200),
    isDefault: joi_1.default.boolean(),
});
//# sourceMappingURL=addressValidators.js.map
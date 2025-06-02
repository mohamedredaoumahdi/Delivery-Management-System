"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateLocationSchema = void 0;
const joi_1 = __importDefault(require("joi"));
exports.updateLocationSchema = joi_1.default.object({
    latitude: joi_1.default.number().required().min(-90).max(90),
    longitude: joi_1.default.number().required().min(-180).max(180),
});
//# sourceMappingURL=deliveryValidators.js.map
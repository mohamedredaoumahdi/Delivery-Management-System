"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateReviewSchema = exports.createReviewSchema = void 0;
const joi_1 = __importDefault(require("joi"));
exports.createReviewSchema = joi_1.default.object({
    rating: joi_1.default.number().required().min(1).max(5),
    comment: joi_1.default.string().required().min(10).max(500),
    shopId: joi_1.default.string().required(),
    productId: joi_1.default.string(),
});
exports.updateReviewSchema = joi_1.default.object({
    rating: joi_1.default.number().min(1).max(5),
    comment: joi_1.default.string().min(10).max(500),
});
//# sourceMappingURL=reviewValidators.js.map
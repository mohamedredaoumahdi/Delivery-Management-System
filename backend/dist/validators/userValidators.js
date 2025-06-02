"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.changePasswordSchema = exports.updateProfileSchema = void 0;
const joi_1 = __importDefault(require("joi"));
exports.updateProfileSchema = joi_1.default.object({
    name: joi_1.default.string().min(2).max(50),
    phone: joi_1.default.string().pattern(/^\+?[\d\s-]{10,}$/),
});
exports.changePasswordSchema = joi_1.default.object({
    currentPassword: joi_1.default.string().required().min(6),
    newPassword: joi_1.default.string().required().min(6),
});
//# sourceMappingURL=userValidators.js.map
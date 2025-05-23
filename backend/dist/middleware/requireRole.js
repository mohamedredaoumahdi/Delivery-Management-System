"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRole = void 0;
const appError_1 = require("@/utils/appError");
const requireRole = (roles) => {
    return (req, res, next) => {
        if (!req.user) {
            throw new appError_1.AppError('Authentication required.', 401);
        }
        if (!roles.includes(req.user.role)) {
            throw new appError_1.AppError('Insufficient permissions.', 403);
        }
        next();
    };
};
exports.requireRole = requireRole;
//# sourceMappingURL=requireRole.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundHandler = void 0;
const appError_1 = require("@/utils/appError");
const notFoundHandler = (req, res, next) => {
    const err = new appError_1.AppError(`Can't find ${req.originalUrl} on this server!`, 404);
    next(err);
};
exports.notFoundHandler = notFoundHandler;
//# sourceMappingURL=notFoundHandler.js.map
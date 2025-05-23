"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorHandler = void 0;
const client_1 = require("@prisma/client");
const appError_1 = require("@/utils/appError");
const logger_1 = require("@/utils/logger");
const config_1 = require("@/config/config");
const handlePrismaError = (error) => {
    switch (error.code) {
        case 'P2002':
            return new appError_1.AppError('Duplicate field value. Please use another value.', 400);
        case 'P2014':
            return new appError_1.AppError('Invalid ID. Please provide a valid ID.', 400);
        case 'P2003':
            return new appError_1.AppError('Invalid input data. Related record not found.', 400);
        case 'P2025':
            return new appError_1.AppError('Record not found.', 404);
        default:
            return new appError_1.AppError('Database error occurred.', 500);
    }
};
const handleJWTError = () => new appError_1.AppError('Invalid token. Please log in again.', 401);
const handleJWTExpiredError = () => new appError_1.AppError('Your token has expired. Please log in again.', 401);
const sendErrorDev = (err, req, res) => {
    if (req.originalUrl.startsWith('/api')) {
        res.status(err.statusCode).json({
            status: err.status,
            error: err,
            message: err.message,
            stack: err.stack,
        });
    }
};
const sendErrorProd = (err, req, res) => {
    if (req.originalUrl.startsWith('/api')) {
        if (err.isOperational) {
            res.status(err.statusCode).json({
                status: err.status,
                message: err.message,
            });
        }
        else {
            logger_1.logger.error('Unexpected error:', err);
            res.status(500).json({
                status: 'error',
                message: 'Something went wrong!',
            });
        }
    }
};
const errorHandler = (err, req, res, next) => {
    err.statusCode = err.statusCode || 500;
    err.status = err.status || 'error';
    if (config_1.config.nodeEnv === 'development') {
        sendErrorDev(err, req, res);
    }
    else {
        let error = { ...err };
        error.message = err.message;
        if (error instanceof client_1.Prisma.PrismaClientKnownRequestError) {
            error = handlePrismaError(error);
        }
        if (error.name === 'JsonWebTokenError')
            error = handleJWTError();
        if (error.name === 'TokenExpiredError')
            error = handleJWTExpiredError();
        sendErrorProd(error, req, res);
    }
};
exports.errorHandler = errorHandler;
//# sourceMappingURL=errorHandler.js.map
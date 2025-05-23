"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.swaggerSpec = void 0;
const swagger_jsdoc_1 = __importDefault(require("swagger-jsdoc"));
const swaggerDefinition = {
    openapi: '3.0.0',
    info: {
        title: 'Delivery System API Documentation',
        version: '1.0.0',
        description: 'API documentation for the Delivery System backend application.',
    },
    servers: [
        {
            url: '/api/v1',
            description: 'Development server',
        },
    ],
};
const options = {
    swaggerDefinition,
    apis: ['./src/routes/*.ts', './src/models/*.ts'],
};
exports.swaggerSpec = (0, swagger_jsdoc_1.default)(options);
//# sourceMappingURL=swagger.js.map
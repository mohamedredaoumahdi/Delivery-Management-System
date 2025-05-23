// src/config/swagger.ts

import swaggerJSDoc from 'swagger-jsdoc';

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
  // @todo: Add security schemes (e.g., Bearer Auth for JWT)
  // components: {
  //   securitySchemes: {
  //     bearerAuth: {
  //       type: 'http',
  //       scheme: 'bearer',
  //       bearerFormat: 'JWT',
  //     },
  //   },
  // },
  // security: [
  //   {
  //     bearerAuth: [],
  //   },
  // ],
};

const options = {
  swaggerDefinition,
  // Paths to files containing OpenAPI definitions
  apis: ['./src/routes/*.ts', './src/models/*.ts'], // @todo: Adjust paths as needed
};

export const swaggerSpec = swaggerJSDoc(options); 
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
      url: '/api',
      description: 'API base path',
    },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
    },
  },
  security: [
    {
      bearerAuth: [],
    },
  ],
};

const options = {
  swaggerDefinition,
  // Paths to files containing OpenAPI definitions
  apis: ['./src/routes/*.ts'],
};

export const swaggerSpec = swaggerJSDoc(options); 
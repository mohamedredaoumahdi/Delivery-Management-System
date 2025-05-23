# Delivery System Backend

This is the backend service for the Delivery System application.

## Prerequisites

- Node.js (v18 or higher)
- Docker and Docker Compose
- PostgreSQL (if running locally)
- Redis (if running locally)

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the root directory with the following variables:
```env
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=delivery_system
DB_USER=postgres
DB_PASSWORD=postgres

# JWT
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=24h

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
```

3. Start the development environment:
```bash
# Start PostgreSQL and Redis using Docker
docker-compose up -d

# Run database migrations
npm run migrate

# Seed the database (optional)
npm run seed

# Start the development server
npm run dev
```

## Available Scripts

- `npm start`: Start the production server
- `npm run dev`: Start the development server with hot-reload
- `npm test`: Run tests
- `npm run migrate`: Run database migrations
- `npm run seed`: Seed the database with sample data

## Project Structure

```
backend/
├── src/
│   ├── config/          # Database, JWT, environment configs
│   ├── controllers/     # Route handlers (API endpoints)
│   ├── middleware/      # Auth, validation, error handling
│   ├── models/          # Database models
│   ├── routes/          # API route definitions
│   ├── services/        # Business logic layer
│   ├── utils/           # Helper functions
│   └── validators/      # Request validation schemas
├── migrations/          # Database migrations
├── seeders/            # Sample data
├── tests/              # API tests
├── docker-compose.yml   # PostgreSQL + Redis setup
├── Dockerfile          # Backend containerization
└── package.json
```

## API Documentation

API documentation will be available at `/api-docs` when running the server.

## Testing

Run the test suite:
```bash
npm test
```

## Docker

Build and run the application using Docker:
```bash
docker-compose up --build
``` 
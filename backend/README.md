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

2. Create a `.env` file in the root directory (see `.env.example`) with at least:
```env
NODE_ENV=development
PORT=8000
DATABASE_URL=postgresql://admin:admin123@localhost:5432/delivery_system
REDIS_URL=redis://localhost:6379
JWT_SECRET=replace-me
JWT_REFRESH_SECRET=replace-me-refresh
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
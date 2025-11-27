# Installation Guide

Complete installation guide for the Delivery Management System.

## Prerequisites

Before installing the system, ensure you have the following installed:

- **Node.js** (v18 or higher)
- **Flutter** (v3.7.0 or higher)
- **Docker** and **Docker Compose**
- **PostgreSQL** (or use Docker)
- **Git**

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Delivery-Management-System
```

### 2. Backend Setup

#### 2.1 Install Dependencies

```bash
cd backend
npm install
```

#### 2.2 Environment Configuration

Create a `.env` file in the `backend` directory:

```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/delivery_db"

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Server
PORT=3000
NODE_ENV=development
CORS_ORIGIN=*

# Redis (optional)
REDIS_URL=redis://localhost:6379

# Email (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-password

# File Upload
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=5242880
```

#### 2.3 Database Setup

Using Docker (Recommended):

```bash
cd backend
docker-compose up -d
```

This will start PostgreSQL and Redis containers.

#### 2.4 Run Migrations

```bash
npm run prisma:migrate
```

#### 2.5 Seed Database (Optional)

```bash
npm run seed
```

This creates:
- Admin user: `admin@example.com` / `password123`
- Sample vendors, customers, and delivery drivers
- Sample shops and products

#### 2.6 Start Backend Server

```bash
npm run dev
```

The backend will be available at `http://localhost:3000`

### 3. Flutter Apps Setup

#### 3.1 Install Flutter Dependencies

**Option 1: Using Melos (Recommended)**

From the root directory:

```bash
# Install melos if not already installed
dart pub global activate melos

# Bootstrap all dependencies
melos bootstrap
```

This installs dependencies for all Flutter apps and packages automatically.

**Option 2: Manual Setup (If Melos doesn't work)**

If `melos bootstrap` doesn't work, you can install dependencies manually:

```bash
# First, install package dependencies
cd packages/core && flutter pub get && cd ../..
cd packages/domain && flutter pub get && cd ../..
cd packages/data && flutter pub get && cd ../..
cd packages/ui_kit && flutter pub get && cd ../..

# Then, install app dependencies
cd apps/user_app && flutter pub get && cd ../..
cd apps/vendor_app && flutter pub get && cd ../..
cd apps/delivery_app && flutter pub get && cd ../..
cd apps/admin_app && flutter pub get && cd ../..
```

**Note:** Always install package dependencies before app dependencies, as apps depend on the packages.

#### 3.2 Configure Apps

Each app has its own configuration. Update the API base URL in:

- `apps/user_app/lib/config/app_config.dart`
- `apps/vendor_app/lib/config/app_config.dart`
- `apps/delivery_app/lib/config/app_config.dart`
- `apps/admin_app/lib/config/app_config.dart`

Change `apiBaseUrl` to match your backend URL.

#### 3.3 Run Apps

**User App (Customer):**
```bash
cd apps/user_app
flutter run -d chrome
```

**Vendor App:**
```bash
cd apps/vendor_app
flutter run -d chrome
```

**Delivery App:**
```bash
cd apps/delivery_app
flutter run -d chrome
```

**Admin App (Web):**
```bash
cd apps/admin_app
flutter run -d chrome
```

## White-label Configuration

### 1. Update Configuration File

Edit `config/whitelabel.json` to customize:

- App name and branding
- Colors and logos
- Feature flags
- Payment settings
- API endpoints

### 2. Apply Configuration

The configuration is automatically loaded by the apps. For backend, restart the server after changes.

## Production Deployment

### Backend

1. Set `NODE_ENV=production` in `.env`
2. Update `DATABASE_URL` to production database
3. Set secure `JWT_SECRET`
4. Configure CORS origins
5. Build and deploy:

```bash
npm run build
npm start
```

### Flutter Apps

1. Update API base URLs to production
2. Build for production:

**Web:**
```bash
flutter build web --release
```

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Troubleshooting

### Database Connection Issues

- Ensure PostgreSQL is running
- Check `DATABASE_URL` in `.env`
- Verify Docker containers are up: `docker ps`

### CORS Errors

- Update `CORS_ORIGIN` in backend `.env`
- Add your frontend URLs to allowed origins

### Flutter Build Issues

- Run `flutter clean`
- Run `melos clean`
- Run `melos bootstrap` again

## Support

For issues or questions:
- Email: support@example.com
- Documentation: See `docs/` folder
- GitHub Issues: [Create an issue]

## Next Steps

After installation:
1. Configure white-label settings
2. Set up payment gateway
3. Configure email/SMS notifications
4. Customize branding
5. Review security settings


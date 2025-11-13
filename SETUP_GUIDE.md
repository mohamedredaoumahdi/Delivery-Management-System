# Setup Guide - Delivery Management System

This guide will walk you through installing all required tools and dependencies to run this project successfully.

---

## Prerequisites Checklist

### ✅ Required Software

1. **Git** - Version control
2. **Node.js** (v18.0.0 or higher) - For TypeScript backend
3. **Flutter SDK** (^3.7.0 or ^3.10.0) - For mobile apps
4. **Dart SDK** (^3.7.0) - Included with Flutter
5. **Docker & Docker Compose** - For databases and services
6. **Python 3.x** - For Python backend (optional, if using FastAPI backend)
7. **PostgreSQL** (15+) - Database (or use Docker)
8. **Redis** (7+) - Caching (or use Docker)

### ✅ Platform-Specific Requirements

#### For Android Development:
- **Android Studio** or **Android SDK**
- **Java Development Kit (JDK)** 11 or higher
- **Gradle** (usually bundled with Android Studio)

#### For iOS Development (macOS only):
- **Xcode** (latest version)
- **CocoaPods** (installed via Flutter or separately)
- **Xcode Command Line Tools**

#### For Web Development:
- Modern web browser (Chrome, Firefox, Safari, Edge)

---

## Installation Instructions

### 1. Install Git

**macOS:**
```bash
# Git usually comes pre-installed. Check with:
git --version

# If not installed, install via Homebrew:
brew install git
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install git
```

**Windows:**
Download from: https://git-scm.com/download/win

---

### 2. Install Node.js and npm

**macOS (using Homebrew):**
```bash
brew install node@18
# or for latest LTS:
brew install node
```

**macOS (using nvm - Recommended):**
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Node.js 18
nvm install 18
nvm use 18
```

**Linux (using nvm - Recommended):**
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

# Install Node.js 18
nvm install 18
nvm use 18
```

**Windows:**
Download from: https://nodejs.org/ (LTS version)

**Verify installation:**
```bash
node --version  # Should be >= 18.0.0
npm --version
```

---

### 3. Install Flutter SDK

**macOS:**
```bash
# Using Homebrew (easiest)
brew install --cask flutter

# Or download manually:
# 1. Download from: https://docs.flutter.dev/get-started/install/macos
# 2. Extract to desired location
# 3. Add to PATH
```

**Linux:**
```bash
# Download Flutter
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$PATH:$HOME/development/flutter/bin"

# Verify
flutter --version
```

**Windows:**
1. Download from: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add to PATH: `C:\src\flutter\bin`
4. Run `flutter doctor` to check setup

**After installation, run:**
```bash
flutter doctor
flutter doctor --android-licenses  # Accept Android licenses
```

**Install Flutter dependencies:**
```bash
flutter pub global activate melos
```

---

### 4. Install Docker and Docker Compose

**macOS:**
```bash
# Using Homebrew
brew install --cask docker

# Or download Docker Desktop from:
# https://www.docker.com/products/docker-desktop
```

**Linux (Ubuntu/Debian):**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**Windows:**
Download Docker Desktop from: https://www.docker.com/products/docker-desktop

**Verify installation:**
```bash
docker --version
docker-compose --version
```

---

### 5. Install Python 3.x (Optional - for FastAPI backend)

**macOS:**
```bash
# Python 3 usually pre-installed. Check:
python3 --version

# If not, install via Homebrew:
brew install python@3.11
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv
```

**Windows:**
Download from: https://www.python.org/downloads/

**Verify installation:**
```bash
python3 --version
pip3 --version
```

---

### 6. Platform-Specific Setup

#### Android Development Setup

**macOS/Linux:**
1. Install Android Studio: https://developer.android.com/studio
2. Open Android Studio → SDK Manager
3. Install:
   - Android SDK Platform 34
   - Android SDK Build-Tools
   - Android Emulator
   - Android SDK Platform-Tools

**Set Android environment variables:**
```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
# or
export ANDROID_HOME=$HOME/Android/Sdk  # Linux

export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

**Verify:**
```bash
flutter doctor
# Should show Android toolchain as installed
```

#### iOS Development Setup (macOS only)

1. Install Xcode from App Store
2. Install Xcode Command Line Tools:
```bash
xcode-select --install
```

3. Install CocoaPods:
```bash
sudo gem install cocoapods
```

4. Accept Xcode license:
```bash
sudo xcodebuild -license accept
```

**Verify:**
```bash
flutter doctor
# Should show iOS toolchain as installed
```

---

## Project Setup Steps

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd Delivery-Management-System
```

### Step 2: Set Up Backend Infrastructure (Docker)

```bash
cd backend

# Start PostgreSQL and Redis using Docker Compose
docker-compose up -d

# Verify containers are running
docker ps
```

This will start:
- PostgreSQL on port `5432`
- Redis on port `6379`
- pgAdmin on port `5050` (optional)

### Step 3: Set Up TypeScript Backend

```bash
cd backend

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env  # If .env.example exists
# Or create .env file with:
# DATABASE_URL="postgresql://admin:admin123@localhost:5432/delivery_system"
# REDIS_URL="redis://localhost:6379"
# JWT_SECRET="your-super-secret-jwt-key-here"
# JWT_REFRESH_SECRET="your-super-secret-refresh-key-here"

# Generate Prisma client
npm run db:generate

# Run database migrations
npm run db:migrate

# (Optional) Seed the database
npm run db:seed

# Start development server
npm run dev
```

Backend will run on `http://localhost:3000`

### Step 4: Set Up Python Backend (Optional)

```bash
cd backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# macOS/Linux:
source venv/bin/activate
# Windows:
# venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables (create .env file)
# DATABASE_URL="postgresql://admin:admin123@localhost:5432/delivery_system"

# Run database migrations (if using Alembic)
alembic upgrade head

# Start development server
uvicorn app.main:app --reload
```

Python backend will run on `http://localhost:8000`

### Step 5: Set Up Flutter Workspace

```bash
# From project root
cd /Users/mro/Documents/Projects/Delivery-Management-System

# Install Melos globally (if not already installed)
flutter pub global activate melos

# Bootstrap the workspace (installs all dependencies)
melos bootstrap

# Or manually install dependencies for each app:
cd apps/user_app && flutter pub get
cd ../vendor_app && flutter pub get
cd ../delivery_app && flutter pub get

# Install dependencies for packages:
cd ../../packages/core && flutter pub get
cd ../data && flutter pub get
cd ../domain && flutter pub get
cd ../ui_kit && flutter pub get
```

### Step 6: Generate Code (Flutter)

```bash
# Generate code for all apps (if using code generation)
cd apps/user_app
flutter pub run build_runner build --delete-conflicting-outputs

cd ../vendor_app
flutter pub run build_runner build --delete-conflicting-outputs

cd ../delivery_app
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 7: Configure API Endpoints

Update API base URLs in each Flutter app's configuration files to point to your backend:
- TypeScript backend: `http://localhost:3000` (or your server URL)
- Python backend: `http://localhost:8000` (or your server URL)

### Step 8: Set Up Firebase (for Push Notifications)

1. Create Firebase project: https://console.firebase.google.com/
2. Add Android/iOS apps to Firebase project
3. Download configuration files:
   - `google-services.json` → `apps/*/android/app/`
   - `GoogleService-Info.plist` → `apps/*/ios/Runner/`
4. Follow Flutter Firebase setup: https://firebase.flutter.dev/

### Step 9: Set Up Google Maps API

1. Get API key from: https://console.cloud.google.com/
2. Enable Maps SDK for Android and iOS
3. Add API key to:
   - Android: `apps/*/android/app/src/main/AndroidManifest.xml`
   - iOS: `apps/*/ios/Runner/AppDelegate.swift`

---

## Running the Applications

### Start Backend Services

```bash
# Start Docker services
cd backend
docker-compose up -d

# Start TypeScript backend
npm run dev

# Or start Python backend (in separate terminal)
source venv/bin/activate
uvicorn app.main:app --reload
```

### Run Flutter Apps

**User App:**
```bash
cd apps/user_app
flutter run
```

**Vendor App:**
```bash
cd apps/vendor_app
flutter run
```

**Delivery App:**
```bash
cd apps/delivery_app
flutter run
```

### Using Melos Commands

```bash
# Run all tests
melos test

# Analyze all packages
melos analyze

# Format all code
melos format

# Build specific app
melos build:user
melos build:vendor
melos build:delivery
```

---

## Environment Variables

Create `.env` files in the `backend/` directory with:

```env
# Database
DATABASE_URL="postgresql://admin:admin123@localhost:5432/delivery_system"

# Redis
REDIS_URL="redis://localhost:6379"

# JWT
JWT_SECRET="your-super-secret-jwt-key-here-change-this"
JWT_REFRESH_SECRET="your-super-secret-refresh-key-here-change-this"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"

# Server
NODE_ENV="development"
PORT=3000
CORS_ORIGIN="*"

# Email (for nodemailer)
SMTP_HOST="smtp.gmail.com"
SMTP_PORT=587
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# Stripe (if using payments)
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_PUBLISHABLE_KEY="pk_test_..."

# Firebase (if using)
FIREBASE_PROJECT_ID="your-project-id"
FIREBASE_PRIVATE_KEY="..."
FIREBASE_CLIENT_EMAIL="..."

# Google Maps
GOOGLE_MAPS_API_KEY="your-google-maps-api-key"
```

---

## Troubleshooting

### Flutter Issues

**"Flutter doctor" shows issues:**
- Run `flutter doctor` to see what's missing
- Follow the suggested fixes
- For Android: Accept licenses with `flutter doctor --android-licenses`

**"Command not found: melos":**
```bash
flutter pub global activate melos
export PATH="$PATH:$HOME/.pub-cache/bin"  # Add to ~/.bashrc or ~/.zshrc
```

**Build errors:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Backend Issues

**Database connection errors:**
- Ensure Docker containers are running: `docker ps`
- Check DATABASE_URL in `.env` file
- Verify PostgreSQL is accessible: `docker-compose logs postgres`

**Prisma errors:**
```bash
# Reset Prisma client
npm run db:generate
npm run db:migrate
```

**Port already in use:**
- Change port in `.env` or `docker-compose.yml`
- Kill process using port: `lsof -ti:3000 | xargs kill`

### Docker Issues

**Docker not running:**
- Start Docker Desktop (macOS/Windows)
- Start Docker service: `sudo systemctl start docker` (Linux)

**Container errors:**
```bash
# View logs
docker-compose logs

# Restart containers
docker-compose restart

# Rebuild containers
docker-compose up -d --build
```

---

## Quick Start Summary

```bash
# 1. Install prerequisites (see above)
# 2. Clone repository
git clone <repo-url> && cd Delivery-Management-System

# 3. Start infrastructure
cd backend && docker-compose up -d

# 4. Set up TypeScript backend
npm install
npm run db:generate
npm run db:migrate
npm run dev

# 5. Set up Flutter (in new terminal)
cd ..
melos bootstrap
cd apps/user_app && flutter run
```

---

## Additional Resources

- **Flutter Documentation**: https://docs.flutter.dev/
- **Dart Documentation**: https://dart.dev/
- **Node.js Documentation**: https://nodejs.org/docs/
- **Prisma Documentation**: https://www.prisma.io/docs/
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **Docker Documentation**: https://docs.docker.com/

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review error messages carefully
3. Ensure all prerequisites are installed correctly
4. Verify environment variables are set correctly
5. Check that Docker containers are running


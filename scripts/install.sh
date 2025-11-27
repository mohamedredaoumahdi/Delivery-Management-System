#!/bin/bash

# Delivery Management System Installation Script
# This script automates the installation process

set -e

echo "🚀 Delivery Management System - Installation Script"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo "📋 Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js is not installed. Please install Node.js v18 or higher.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Node.js $(node --version)${NC}"
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter is not installed. Please install Flutter v3.7.0 or higher.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Flutter $(flutter --version | head -n 1)${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️  Docker is not installed. Database setup will be skipped.${NC}"
    else
        echo -e "${GREEN}✅ Docker $(docker --version)${NC}"
    fi
    
    # Check Melos
    if ! command -v melos &> /dev/null; then
        echo -e "${YELLOW}⚠️  Melos is not installed. Installing globally...${NC}"
        dart pub global activate melos
    fi
    echo -e "${GREEN}✅ Melos installed${NC}"
    
    echo ""
}

# Setup backend
setup_backend() {
    echo "🔧 Setting up backend..."
    cd backend
    
    # Install dependencies
    echo "📦 Installing backend dependencies..."
    npm install
    
    # Check for .env file
    if [ ! -f .env ]; then
        echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
        cat > .env << EOF
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/delivery_db"

# JWT
JWT_SECRET=change-this-to-a-secure-random-string-in-production
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Server
PORT=3000
NODE_ENV=development
CORS_ORIGIN=*

# Redis
REDIS_URL=redis://localhost:6379

# File Upload
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=5242880
EOF
        echo -e "${YELLOW}⚠️  Please update .env file with your configuration${NC}"
    else
        echo -e "${GREEN}✅ .env file exists${NC}"
    fi
    
    # Setup database with Docker
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        echo "🐳 Starting Docker containers..."
        docker-compose up -d
        echo -e "${GREEN}✅ Docker containers started${NC}"
        
        # Wait for database to be ready
        echo "⏳ Waiting for database to be ready..."
        sleep 5
    else
        echo -e "${YELLOW}⚠️  Docker not available. Please set up PostgreSQL manually.${NC}"
    fi
    
    # Run migrations
    echo "🗄️  Running database migrations..."
    npm run prisma:migrate || echo -e "${YELLOW}⚠️  Migrations failed. Please check database connection.${NC}"
    
    # Seed database (optional)
    read -p "Do you want to seed the database with sample data? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🌱 Seeding database..."
        npm run seed || echo -e "${YELLOW}⚠️  Seeding failed.${NC}"
    fi
    
    cd ..
    echo -e "${GREEN}✅ Backend setup complete${NC}"
    echo ""
}

# Setup Flutter apps
setup_flutter() {
    echo "📱 Setting up Flutter apps..."
    
    # Install Melos dependencies
    echo "📦 Installing Flutter dependencies..."
    melos bootstrap
    
    echo -e "${GREEN}✅ Flutter setup complete${NC}"
    echo ""
}

# Create config directory
setup_config() {
    echo "⚙️  Setting up configuration..."
    
    if [ ! -d "config" ]; then
        mkdir config
    fi
    
    if [ ! -f "config/whitelabel.json" ]; then
        echo -e "${YELLOW}⚠️  Whitelabel config not found. Using default.${NC}"
        # Config file should be created manually or copied from template
    else
        echo -e "${GREEN}✅ Configuration files found${NC}"
    fi
    
    echo ""
}

# Main installation
main() {
    check_prerequisites
    setup_backend
    setup_flutter
    setup_config
    
    echo "=================================================="
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Update backend/.env with your configuration"
    echo "2. Update config/whitelabel.json for branding"
    echo "3. Start backend: cd backend && npm run dev"
    echo "4. Run Flutter apps: cd apps/[app_name] && flutter run"
    echo ""
    echo "For more information, see INSTALLATION.md"
}

# Run main function
main


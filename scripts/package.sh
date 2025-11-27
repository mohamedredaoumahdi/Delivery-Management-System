#!/bin/bash

# Package Creation Script for CodeCanyon
# This script creates a distribution package

set -e

PACKAGE_NAME="delivery-management-system"
VERSION="1.0.0"
OUTPUT_DIR="dist/${PACKAGE_NAME}-v${VERSION}"

echo "📦 Creating distribution package..."
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy main files (excluding ephemeral and build artifacts)
echo "📋 Copying files..."
rsync -av --exclude='ephemeral' --exclude='.dart_tool' --exclude='build' --exclude='.symlinks' --exclude='Pods' --exclude='node_modules' apps "$OUTPUT_DIR/" 2>/dev/null || cp -r apps "$OUTPUT_DIR/"
rsync -av --exclude='node_modules' --exclude='dist' --exclude='build' --exclude='.dart_tool' backend "$OUTPUT_DIR/" 2>/dev/null || cp -r backend "$OUTPUT_DIR/"
rsync -av --exclude='.dart_tool' --exclude='build' packages "$OUTPUT_DIR/" 2>/dev/null || cp -r packages "$OUTPUT_DIR/"
cp -r config "$OUTPUT_DIR/"
cp -r scripts "$OUTPUT_DIR/"

# Copy documentation
cp INSTALLATION.md "$OUTPUT_DIR/"
cp CONFIGURATION.md "$OUTPUT_DIR/"
cp USER_MANUAL.md "$OUTPUT_DIR/"
cp FEATURES.md "$OUTPUT_DIR/"
cp CODE_CANYON_PACKAGE.md "$OUTPUT_DIR/"
cp CODECANYON_ITEM_DESCRIPTION.md "$OUTPUT_DIR/" 2>/dev/null || true
cp README.md "$OUTPUT_DIR/"
cp LICENSE "$OUTPUT_DIR/" 2>/dev/null || true
cp CHANGELOG.md "$OUTPUT_DIR/" 2>/dev/null || true
cp SYSTEM_DOCUMENTATION.md "$OUTPUT_DIR/" 2>/dev/null || true

# Copy root files
cp melos.yaml "$OUTPUT_DIR/" 2>/dev/null || true
cp .gitignore "$OUTPUT_DIR/" 2>/dev/null || true

# Remove unnecessary files
echo "🧹 Cleaning up..."
# Remove directories that shouldn't be in distribution
find "$OUTPUT_DIR" -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name ".dart_tool" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name "build" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name "dist" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name ".symlinks" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name "Pods" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name ".git" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name "ephemeral" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name "coverage" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name ".idea" -exec rm -rf {} + 2>/dev/null || true
find "$OUTPUT_DIR" -type d -name ".vscode" -exec rm -rf {} + 2>/dev/null || true
# Remove files that shouldn't be in distribution
find "$OUTPUT_DIR" -type f -name "*.log" -delete 2>/dev/null || true
find "$OUTPUT_DIR" -type f -name ".DS_Store" -delete 2>/dev/null || true
find "$OUTPUT_DIR" -type f -name "*.lock" -not -name "package-lock.json" -not -name "pubspec.lock" -delete 2>/dev/null || true
find "$OUTPUT_DIR" -type f -name "*.tsbuildinfo" -delete 2>/dev/null || true
find "$OUTPUT_DIR" -type f -name ".flutter-plugins-dependencies" -delete 2>/dev/null || true
find "$OUTPUT_DIR" -type f -name "*.iml" -delete 2>/dev/null || true

# Create .env.example files
echo "📝 Creating .env examples..."
if [ ! -f "$OUTPUT_DIR/backend/.env.example" ]; then
    cat > "$OUTPUT_DIR/backend/.env.example" << 'EOF'
# Database Configuration
DATABASE_URL="postgresql://user:password@localhost:5432/delivery_db"

# JWT Security
# IMPORTANT: Change these to secure random strings in production!
# Generate secure secrets: openssl rand -base64 32
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-min-32-characters
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production-min-32-characters
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Server Configuration
PORT=3000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000

# CORS Configuration
# In production, specify exact origins: http://localhost:3000,https://yourdomain.com
# DO NOT use "*" in production!
CORS_ORIGIN=*

# Redis Configuration (Optional - for caching)
REDIS_URL=redis://localhost:6379

# Email Configuration (Optional - for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=noreply@deliverysystem.com
FROM_NAME=Delivery System

# File Upload Configuration
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760
ALLOWED_IMAGE_TYPES=image/jpeg,image/png,image/webp

# API Configuration
API_VERSION=v1

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF
fi

# Create LICENSE file if doesn't exist
if [ ! -f "$OUTPUT_DIR/LICENSE" ]; then
    cat > "$OUTPUT_DIR/LICENSE" << 'EOF'
MIT License

Copyright (c) 2024 Delivery Management System

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
fi

# Create package info file
cat > "$OUTPUT_DIR/PACKAGE_INFO.txt" << EOF
Delivery Management System
Version: ${VERSION}
Package Date: $(date +%Y-%m-%d)

Contents:
- 4 Flutter Applications (Customer, Vendor, Delivery, Admin)
- Backend API (Node.js/TypeScript)
- Complete Documentation
- Installation Scripts
- White-label Configuration

See INSTALLATION.md for setup instructions.
EOF

# Create zip file
echo "📦 Creating zip archive..."
cd dist
zip -r "${PACKAGE_NAME}-v${VERSION}.zip" "${PACKAGE_NAME}-v${VERSION}" -x "*.git*" "*.DS_Store*"
cd ..

echo ""
echo "✅ Package created successfully!"
echo "📦 Location: ${OUTPUT_DIR}"
echo "📦 Zip file: dist/${PACKAGE_NAME}-v${VERSION}.zip"
echo ""
echo "Package size:"
du -sh "$OUTPUT_DIR"
du -sh "dist/${PACKAGE_NAME}-v${VERSION}.zip"


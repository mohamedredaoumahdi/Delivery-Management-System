#!/bin/bash

# Create Admin User Script
# This script creates an admin user for the system

set -e

echo "👤 Creating admin user..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please create it first."
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL not set in .env file"
    exit 1
fi

# Prompt for admin details
read -p "Enter admin email: " ADMIN_EMAIL
read -p "Enter admin name: " ADMIN_NAME
read -sp "Enter admin password: " ADMIN_PASSWORD
echo

# Create admin user using Node.js script
node -e "
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function createAdmin() {
  try {
    const hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD, 10);
    const admin = await prisma.user.create({
      data: {
        email: process.env.ADMIN_EMAIL,
        name: process.env.ADMIN_NAME,
        passwordHash: hashedPassword,
        role: 'ADMIN',
        isEmailVerified: true,
        isActive: true,
      },
    });
    console.log('✅ Admin user created successfully!');
    console.log('Email:', admin.email);
    console.log('ID:', admin.id);
  } catch (error) {
    console.error('❌ Error creating admin:', error.message);
    process.exit(1);
  } finally {
    await prisma.\$disconnect();
  }
}

createAdmin();
" ADMIN_EMAIL="$ADMIN_EMAIL" ADMIN_NAME="$ADMIN_NAME" ADMIN_PASSWORD="$ADMIN_PASSWORD"

echo "✅ Admin user creation complete!"


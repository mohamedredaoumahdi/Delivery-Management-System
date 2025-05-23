import { PrismaClient, UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Start seeding ...');

  const passwordHash = await bcrypt.hash('password123', 12);

  // Create sample users
  const adminUser = await prisma.user.create({
    data: {
      email: 'admin@example.com',
      name: 'Admin User',
      passwordHash: passwordHash,
      role: UserRole.ADMIN,
      isEmailVerified: true,
    },
  });

  const vendorUser = await prisma.user.create({
    data: {
      email: 'vendor@example.com',
      name: 'Vendor User',
      passwordHash: passwordHash,
      role: UserRole.VENDOR,
      isEmailVerified: true,
    },
  });

  const customerUser = await prisma.user.create({
    data: {
      email: 'customer@example.com',
      name: 'Customer User',
      passwordHash: passwordHash,
      role: UserRole.CUSTOMER,
      isEmailVerified: true,
    },
  });

  const deliveryUser = await prisma.user.create({
    data: {
      email: 'delivery@example.com',
      name: 'Delivery User',
      passwordHash: passwordHash,
      role: UserRole.DELIVERY,
      isEmailVerified: true,
    },
  });

  console.log('Created sample users:', { adminUser, vendorUser, customerUser, deliveryUser });

  console.log('Seeding finished.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  }); 
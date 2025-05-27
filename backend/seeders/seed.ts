import { PrismaClient, UserRole, ShopCategory } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Start seeding ...');

  const passwordHash = await bcrypt.hash('password123', 12);

  // Create sample users (with upsert to avoid duplicates)
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      email: 'admin@example.com',
      name: 'Admin User',
      passwordHash: passwordHash,
      role: UserRole.ADMIN,
      isEmailVerified: true,
    },
  });

  const vendorUser = await prisma.user.upsert({
    where: { email: 'vendor@example.com' },
    update: {},
    create: {
      email: 'vendor@example.com',
      name: 'Vendor User',
      passwordHash: passwordHash,
      role: UserRole.VENDOR,
      isEmailVerified: true,
    },
  });

  const customerUser = await prisma.user.upsert({
    where: { email: 'customer@example.com' },
    update: {},
    create: {
      email: 'customer@example.com',
      name: 'Customer User',
      passwordHash: passwordHash,
      role: UserRole.CUSTOMER,
      isEmailVerified: true,
    },
  });

  const deliveryUser = await prisma.user.upsert({
    where: { email: 'delivery@example.com' },
    update: {},
    create: {
      email: 'delivery@example.com',
      name: 'Delivery User',
      passwordHash: passwordHash,
      role: UserRole.DELIVERY,
      isEmailVerified: true,
    },
  });

  console.log('Created sample users');

  // Check if shops already exist
  const existingShops = await prisma.shop.count();
  if (existingShops === 0) {
    // Create sample shops
    const pizzaShop = await prisma.shop.create({
      data: {
        name: 'Mario\'s Pizza Palace',
        description: 'Authentic Italian pizza made with fresh ingredients',
        category: ShopCategory.RESTAURANT,
        logoUrl: null,
        coverImageUrl: null,
        address: '123 Main Street, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        phone: '+1-555-0123',
        email: 'pizza@example.com',
        website: 'https://mariospizza.com',
        openingHours: JSON.stringify({
          monday: { open: '11:00', close: '22:00' },
          tuesday: { open: '11:00', close: '22:00' },
          wednesday: { open: '11:00', close: '22:00' },
          thursday: { open: '11:00', close: '22:00' },
          friday: { open: '11:00', close: '23:00' },
          saturday: { open: '11:00', close: '23:00' },
          sunday: { open: '12:00', close: '21:00' }
        }),
        rating: 4.5,
        ratingCount: 127,
        isOpen: true,
        hasDelivery: true,
        hasPickup: true,
        minimumOrderAmount: 15.0,
        deliveryFee: 3.99,
        estimatedDeliveryTime: 30,
        isActive: true,
        isFeatured: true,
        ownerId: vendorUser.id,
      },
    });

    const groceryShop = await prisma.shop.create({
      data: {
        name: 'Fresh Market',
        description: 'Your neighborhood grocery store with fresh produce and daily essentials',
        category: ShopCategory.GROCERY,
        logoUrl: null,
        coverImageUrl: null,
        address: '456 Oak Avenue, Uptown',
        latitude: 40.7589,
        longitude: -73.9851,
        phone: '+1-555-0456',
        email: 'grocery@example.com',
        openingHours: JSON.stringify({
          monday: { open: '08:00', close: '20:00' },
          tuesday: { open: '08:00', close: '20:00' },
          wednesday: { open: '08:00', close: '20:00' },
          thursday: { open: '08:00', close: '20:00' },
          friday: { open: '08:00', close: '21:00' },
          saturday: { open: '08:00', close: '21:00' },
          sunday: { open: '09:00', close: '19:00' }
        }),
        rating: 4.2,
        ratingCount: 89,
        isOpen: true,
        hasDelivery: true,
        hasPickup: true,
        minimumOrderAmount: 25.0,
        deliveryFee: 4.99,
        estimatedDeliveryTime: 45,
        isActive: true,
        isFeatured: false,
        ownerId: vendorUser.id,
      },
    });

    console.log('Created sample shops');

    // Create sample categories
    const pizzaCategory = await prisma.category.create({
      data: {
        name: 'Pizza',
        description: 'Delicious pizzas',
        status: 'ACTIVE',
        shopId: pizzaShop.id,
      },
    });

    const drinksCategory = await prisma.category.create({
      data: {
        name: 'Beverages',
        description: 'Refreshing drinks',
        status: 'ACTIVE',
        shopId: pizzaShop.id,
      },
    });

    const produceCategory = await prisma.category.create({
      data: {
        name: 'Fresh Produce',
        description: 'Fresh fruits and vegetables',
        status: 'ACTIVE',
        shopId: groceryShop.id,
      },
    });

    console.log('Created sample categories');

    // Create sample products
    await prisma.product.create({
      data: {
        name: 'Margherita Pizza',
        description: 'Classic pizza with tomato sauce, mozzarella, and fresh basil',
        price: 14.99,
        imageUrl: null,
        images: [],
        categoryName: 'Pizza',
        categoryId: pizzaCategory.id,
        tags: ['vegetarian', 'classic', 'italian'],
        inStock: true,
        stockQuantity: 50,
        isFeatured: true,
        isActive: true,
        rating: 4.6,
        ratingCount: 45,
        shopId: pizzaShop.id,
      },
    });

    await prisma.product.create({
      data: {
        name: 'Pepperoni Pizza',
        description: 'Classic pizza with tomato sauce, mozzarella, and pepperoni',
        price: 16.99,
        imageUrl: null,
        images: [],
        categoryName: 'Pizza',
        categoryId: pizzaCategory.id,
        tags: ['meat', 'classic', 'popular'],
        inStock: true,
        stockQuantity: 40,
        isFeatured: true,
        isActive: true,
        rating: 4.7,
        ratingCount: 62,
        shopId: pizzaShop.id,
      },
    });

    await prisma.product.create({
      data: {
        name: 'Coca Cola',
        description: 'Classic refreshing cola drink',
        price: 2.99,
        imageUrl: null,
        images: [],
        categoryName: 'Beverages',
        categoryId: drinksCategory.id,
        tags: ['drink', 'cola', 'refreshing'],
        inStock: true,
        stockQuantity: 100,
        isFeatured: false,
        isActive: true,
        rating: 4.3,
        ratingCount: 23,
        shopId: pizzaShop.id,
      },
    });

    await prisma.product.create({
      data: {
        name: 'Fresh Bananas',
        description: 'Ripe yellow bananas, perfect for snacking',
        price: 1.99,
        imageUrl: null,
        images: [],
        categoryName: 'Fresh Produce',
        categoryId: produceCategory.id,
        tags: ['fruit', 'healthy', 'organic'],
        inStock: true,
        stockQuantity: 200,
        isFeatured: true,
        isActive: true,
        rating: 4.4,
        ratingCount: 18,
        shopId: groceryShop.id,
      },
    });

    console.log('Created sample products');
  } else {
    console.log('Shops already exist, skipping shop creation');
  }

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
import { PrismaClient, UserRole, ShopCategory, OrderStatus, PaymentMethod } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

// Helper function to get image URL (placeholder if image doesn't exist)
const getImageUrl = (path: string | null): string | null => {
  if (!path) return null;
  // If image exists, return the path, otherwise return null
  return `/uploads/${path}`;
};

async function main() {
  console.log('Start seeding ...');

  const passwordHash = await bcrypt.hash('password123', 12);

  // Create admin user
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      email: 'admin@example.com',
      name: 'Admin User',
      passwordHash: passwordHash,
      role: UserRole.ADMIN,
      isEmailVerified: true,
      profilePicture: getImageUrl('users/avatars/avatar-admin.jpg'),
    },
  });

  // Create default vendor user (for app login)
  const defaultVendor = await prisma.user.upsert({
    where: { email: 'vendor@example.com' },
    update: {},
    create: {
      email: 'vendor@example.com',
      name: 'Vendor User',
      passwordHash: passwordHash,
      role: UserRole.VENDOR,
      isEmailVerified: true,
      phone: '+1-555-0100',
      profilePicture: getImageUrl('users/avatars/avatar-vendor-1.jpg'),
    },
  });

  // Create multiple vendor users
  const vendorUsers = [defaultVendor];
  const vendorEmails = [
    'vendor1@example.com',
    'vendor2@example.com',
    'vendor3@example.com',
    'vendor4@example.com',
    'vendor5@example.com',
  ];
  const vendorNames = [
    'Mario Rossi',
    'Sarah Johnson',
    'Ahmed Hassan',
    'Emma Wilson',
    'David Chen',
  ];

  // Available vendor avatars: avatar-vendor-1.jpg, avatar-vendor-2.jpg
  const vendorAvatars = [
    'users/avatars/avatar-vendor-2.jpg',
    'users/avatars/avatar-vendor-1.jpg', // Reuse if needed
    'users/avatars/avatar-vendor-2.jpg', // Reuse if needed
    'users/avatars/avatar-vendor-1.jpg', // Reuse if needed
    'users/avatars/avatar-vendor-2.jpg', // Reuse if needed
  ];

  for (let i = 0; i < vendorEmails.length; i++) {
    const vendor = await prisma.user.upsert({
      where: { email: vendorEmails[i] },
      update: {},
      create: {
        email: vendorEmails[i],
        name: vendorNames[i],
      passwordHash: passwordHash,
      role: UserRole.VENDOR,
      isEmailVerified: true,
        phone: `+1-555-${1000 + i}`,
        profilePicture: getImageUrl(vendorAvatars[i] || 'users/avatars/avatar-vendor-1.jpg'),
    },
  });
    vendorUsers.push(vendor);
  }

  // Create default customer user (for app login)
  const defaultCustomer = await prisma.user.upsert({
    where: { email: 'customer@example.com' },
    update: {},
    create: {
      email: 'customer@example.com',
      name: 'Customer User',
      passwordHash: passwordHash,
      role: UserRole.CUSTOMER,
      isEmailVerified: true,
      phone: '+1-555-0200',
      profilePicture: getImageUrl('users/avatars/avatar-customer-1.jpg'),
    },
  });

  // Create multiple customer users
  const customerUsers = [defaultCustomer];
  const customerEmails = [
    'customer1@example.com',
    'customer2@example.com',
    'customer3@example.com',
    'customer4@example.com',
    'customer5@example.com',
  ];
  const customerNames = [
    'John Smith',
    'Maria Garcia',
    'James Brown',
    'Lisa Anderson',
    'Michael Taylor',
  ];

  // Available customer avatars: avatar-customer-1.jpg, avatar-customer-2.jpg, avatar-customer-3.jpg
  const customerAvatars = [
    'users/avatars/avatar-customer-2.jpg',
    'users/avatars/avatar-customer-3.jpg',
    'users/avatars/avatar-customer-1.jpg', // Reuse if needed
    'users/avatars/avatar-customer-2.jpg', // Reuse if needed
    'users/avatars/avatar-customer-3.jpg', // Reuse if needed
  ];

  for (let i = 0; i < customerEmails.length; i++) {
    const customer = await prisma.user.upsert({
      where: { email: customerEmails[i] },
      update: {},
      create: {
        email: customerEmails[i],
        name: customerNames[i],
      passwordHash: passwordHash,
      role: UserRole.CUSTOMER,
      isEmailVerified: true,
        phone: `+1-555-${2000 + i}`,
        profilePicture: getImageUrl(customerAvatars[i] || 'users/avatars/avatar-customer-1.jpg'),
    },
  });
    customerUsers.push(customer);
  }

  // Create default delivery user (for app login)
  const defaultDelivery = await prisma.user.upsert({
    where: { email: 'delivery@example.com' },
    update: {},
    create: {
      email: 'delivery@example.com',
      name: 'Delivery User',
      passwordHash: passwordHash,
      role: UserRole.DELIVERY,
      isEmailVerified: true,
      phone: '+1-555-0300',
      profilePicture: getImageUrl('users/avatars/avatar-delivery-1.jpg'),
    },
  });

  // Create multiple delivery users
  const deliveryUsers = [defaultDelivery];
  const deliveryEmails = [
    'delivery1@example.com',
    'delivery2@example.com',
    'delivery3@example.com',
  ];
  const deliveryNames = [
    'Tom Driver',
    'Alex Rider',
    'Sam Walker',
  ];

  // Available delivery avatars: avatar-delivery-1.jpg, avatar-delivery-2.jpg
  const deliveryAvatars = [
    'users/avatars/avatar-delivery-2.jpg',
    'users/avatars/avatar-delivery-1.jpg', // Reuse if needed
    'users/avatars/avatar-delivery-2.jpg', // Reuse if needed
  ];

  for (let i = 0; i < deliveryEmails.length; i++) {
    const delivery = await prisma.user.upsert({
      where: { email: deliveryEmails[i] },
      update: {},
      create: {
        email: deliveryEmails[i],
        name: deliveryNames[i],
      passwordHash: passwordHash,
      role: UserRole.DELIVERY,
      isEmailVerified: true,
        phone: `+1-555-${3000 + i}`,
        profilePicture: getImageUrl(deliveryAvatars[i] || 'users/avatars/avatar-delivery-1.jpg'),
    },
  });
    deliveryUsers.push(delivery);
  }

  console.log('Created sample users');

  // Check if shops already exist
  const existingShops = await prisma.shop.count();
  if (existingShops === 0) {
    // Define shops data
    // Note: Coordinates are centered around San Francisco so that
    // nearby shops appear correctly for the default app location.
    const shopsData = [
      {
        name: "Mario's Pizza Palace",
        description: 'Authentic Italian pizza made with fresh ingredients and traditional recipes',
        category: ShopCategory.RESTAURANT,
        logoUrl: getImageUrl('shops/logos/logo-pizza-palace.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-pizza-palace.jpg'),
        address: '123 Main Street, Downtown',
        latitude: 37.7749,
        longitude: -122.4194,
        phone: '+1-555-0123',
        email: 'pizza@example.com',
        website: 'https://mariospizza.com',
        rating: 4.5,
        ratingCount: 127,
        minimumOrderAmount: 15.0,
        deliveryRadius: 10.0,
        deliveryFee: 3.99,
        estimatedDeliveryTime: 30,
        isFeatured: true,
        ownerId: vendorUsers[0].id,
      },
      {
        name: 'Fresh Market',
        description: 'Your neighborhood grocery store with fresh produce and daily essentials',
        category: ShopCategory.GROCERY,
        logoUrl: getImageUrl('shops/logos/logo-fresh-market.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-fresh-market.png'),
        address: '456 Oak Avenue, Uptown',
        latitude: 37.7849,
        longitude: -122.4094,
        phone: '+1-555-0456',
        email: 'grocery@example.com',
        rating: 4.2,
        ratingCount: 89,
        minimumOrderAmount: 10.0,
        deliveryRadius: 15.0,
        deliveryFee: 4.99,
        estimatedDeliveryTime: 45,
        isFeatured: false,
        ownerId: vendorUsers[1].id,
      },
      {
        name: 'Burger King Express',
        description: 'Juicy burgers, crispy fries, and delicious sides. Fast and fresh!',
        category: ShopCategory.RESTAURANT,
        logoUrl: getImageUrl('shops/logos/logo-burger-king.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-burger-king.jpg'),
        address: '789 Broadway, Midtown',
        latitude: 37.7649,
        longitude: -122.4294,
        phone: '+1-555-0789',
        email: 'burger@example.com',
        rating: 4.3,
        ratingCount: 156,
        minimumOrderAmount: 12.0,
        deliveryRadius: 10.0,
        deliveryFee: 2.99,
        estimatedDeliveryTime: 25,
        isFeatured: true,
        ownerId: vendorUsers[2].id,
      },
      {
        name: 'Sushi House',
        description: 'Fresh sushi and Japanese cuisine. Traditional recipes with modern flair',
        category: ShopCategory.RESTAURANT,
        logoUrl: getImageUrl('shops/logos/logo-sushi-house.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-sushi-house.jpg'),
        address: '321 Park Avenue, Uptown',
        latitude: 37.7840,
        longitude: -122.3990,
        phone: '+1-555-0321',
        email: 'sushi@example.com',
        rating: 4.7,
        ratingCount: 203,
        minimumOrderAmount: 20.0,
        deliveryRadius: 10.0,
        deliveryFee: 5.99,
        estimatedDeliveryTime: 35,
        isFeatured: true,
        ownerId: vendorUsers[0].id,
      },
      {
        name: 'Coffee Corner',
        description: 'Artisan coffee, fresh pastries, and cozy atmosphere. Your daily caffeine fix!',
        category: ShopCategory.RESTAURANT,
        logoUrl: getImageUrl('shops/logos/logo-coffee-corner.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-coffee-corner.jpg'),
        address: '654 Elm Street, Downtown',
        latitude: 37.7814,
        longitude: -122.4090,
        phone: '+1-555-0654',
        email: 'coffee@example.com',
        rating: 4.6,
        ratingCount: 94,
        minimumOrderAmount: 8.0,
        deliveryRadius: 10.0,
        deliveryFee: 2.49,
        estimatedDeliveryTime: 20,
        isFeatured: false,
        ownerId: vendorUsers[3].id,
      },
      {
        name: 'Pharmacy Plus',
        description: 'Your trusted pharmacy for prescriptions, health products, and wellness items',
        category: ShopCategory.PHARMACY,
        logoUrl: getImageUrl('shops/logos/logo-pharmacy-plus.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-pharmacy-plus.jpg'),
        address: '987 Health Boulevard, Medical District',
        latitude: 37.7682,
        longitude: -122.4292,
        phone: '+1-555-0987',
        email: 'pharmacy@example.com',
        rating: 4.4,
        ratingCount: 67,
        minimumOrderAmount: 15.0,
        deliveryRadius: 10.0,
        deliveryFee: 3.99,
        estimatedDeliveryTime: 30,
        isFeatured: false,
        ownerId: vendorUsers[1].id,
      },
      {
        name: 'Bakery Bliss',
        description: 'Fresh baked bread, pastries, cakes, and desserts. Made with love daily',
        category: ShopCategory.RESTAURANT,
        logoUrl: getImageUrl('shops/logos/logo-bakery-bliss.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-bakery-bliss.jpg'),
        address: '147 Sweet Street, Bakery District',
        latitude: 37.7759,
        longitude: -122.4091,
        phone: '+1-555-0147',
        email: 'bakery@example.com',
        rating: 4.8,
        ratingCount: 142,
        minimumOrderAmount: 10.0,
        deliveryRadius: 10.0,
        deliveryFee: 3.49,
        estimatedDeliveryTime: 25,
        isFeatured: true,
        ownerId: vendorUsers[4].id,
      },
      {
        name: 'Chicken Grill',
        description: 'Crispy fried chicken, wings, and sides. Finger-licking good!',
        category: ShopCategory.RESTAURANT,
        logoUrl: getImageUrl('shops/logos/logo-chicken-grill.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-chicken-grill.jpg'),
        address: '258 Spice Road, Food Court',
        latitude: 37.7714,
        longitude: -122.4242,
        phone: '+1-555-0258',
        email: 'chicken@example.com',
        rating: 4.5,
        ratingCount: 118,
        minimumOrderAmount: 12.0,
        deliveryRadius: 10.0,
        deliveryFee: 3.99,
        estimatedDeliveryTime: 28,
        isFeatured: false,
        ownerId: vendorUsers[2].id,
      },
      {
        name: 'Ice Cream Parlor',
        description: 'Premium ice cream, gelato, and frozen treats. Cool down with us!',
        category: ShopCategory.RESTAURANT,
        logoUrl: getImageUrl('shops/logos/logo-ice-cream-parlor.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-ice-cream-parlor.jpg'),
        address: '369 Chill Avenue, Dessert Lane',
        latitude: 37.7740,
        longitude: -122.4194,
        phone: '+1-555-0369',
        email: 'icecream@example.com',
        rating: 4.6,
        ratingCount: 76,
        minimumOrderAmount: 8.0,
        deliveryRadius: 10.0,
        deliveryFee: 2.99,
        estimatedDeliveryTime: 22,
        isFeatured: false,
        ownerId: vendorUsers[3].id,
      },
      {
        name: 'Fast Food Express',
        description: 'Quick bites, combo meals, and fast service. Your go-to for convenience',
        category: ShopCategory.RESTAURANT,
        logoUrl: getImageUrl('shops/logos/logo-fast-food.jpg'),
        coverImageUrl: getImageUrl('shops/covers/cover-fast-food.jpg'),
        address: '741 Quick Street, Fast Lane',
        latitude: 37.7880,
        longitude: -122.4055,
        phone: '+1-555-0741',
        email: 'fastfood@example.com',
        rating: 4.1,
        ratingCount: 203,
        minimumOrderAmount: 10.0,
        deliveryRadius: 10.0,
        deliveryFee: 2.49,
        estimatedDeliveryTime: 20,
        isFeatured: false,
        ownerId: vendorUsers[4].id,
      },
      {
        name: 'Mega Retail Store',
        description: 'Your one-stop shop for everything! Electronics, clothing, home goods, and more. Shop all categories in one place',
        category: ShopCategory.RETAIL,
        logoUrl: getImageUrl('shops/logos/logo-fresh-market.jpg'), // Reusing logo until retail logo is added
        coverImageUrl: getImageUrl('shops/covers/cover-mega-retail.jpg'),
        address: '850 Commerce Boulevard, Shopping District',
        latitude: 37.7820,
        longitude: -122.4120,
        phone: '+1-555-0850',
        email: 'retail@example.com',
        website: 'https://megaretail.com',
        rating: 4.6,
        ratingCount: 312,
        minimumOrderAmount: 15.0,
        deliveryRadius: 10.0,
        deliveryFee: 4.99,
        estimatedDeliveryTime: 45,
        isFeatured: true,
        ownerId: vendorUsers[0].id,
      },
    ];

    // Create shops
    const shops = [];
    for (const shopData of shopsData) {
      const shop = await prisma.shop.create({
        data: {
          ...shopData,
          openingHours: JSON.stringify({
            monday: { open: '09:00', close: '21:00' },
            tuesday: { open: '09:00', close: '21:00' },
            wednesday: { open: '09:00', close: '21:00' },
            thursday: { open: '09:00', close: '21:00' },
            friday: { open: '09:00', close: '22:00' },
            saturday: { open: '10:00', close: '22:00' },
            sunday: { open: '11:00', close: '20:00' },
          }),
          isOpen: true,
          hasDelivery: true,
          hasPickup: true,
          isActive: true,
        },
      });
      shops.push(shop);
    }

    console.log(`Created ${shops.length} shops`);

    // Create categories for each shop
    const categoriesMap = new Map();

    // Pizza Palace categories
    const pizzaCategories = [
      { name: 'Pizza', description: 'Delicious pizzas', imageUrl: getImageUrl('categories/category-pizza.png') },
      { name: 'Beverages', description: 'Refreshing drinks', imageUrl: getImageUrl('categories/category-beverages.jpeg') },
      { name: 'Sides', description: 'Appetizers and sides', imageUrl: null },
    ];
    for (const cat of pizzaCategories) {
      const category = await prisma.category.create({
        data: {
          ...cat,
          status: 'ACTIVE',
          shopId: shops[0].id,
        },
      });
      categoriesMap.set(`${shops[0].id}-${cat.name}`, category);
    }

    // Fresh Market categories
    const groceryCategories = [
      { name: 'Fresh Produce', description: 'Fresh fruits and vegetables', imageUrl: getImageUrl('categories/category-grocery.png') },
      { name: 'Dairy', description: 'Milk, cheese, and dairy products', imageUrl: null },
      { name: 'Meat & Seafood', description: 'Fresh meat and seafood', imageUrl: null },
      { name: 'Pantry Staples', description: 'Essential grocery items', imageUrl: null },
    ];
    for (const cat of groceryCategories) {
      const category = await prisma.category.create({
        data: {
          ...cat,
          status: 'ACTIVE',
          shopId: shops[1].id,
        },
      });
      categoriesMap.set(`${shops[1].id}-${cat.name}`, category);
    }

    // Burger King categories
    const burgerCategories = [
      { name: 'Burgers', description: 'Juicy burgers', imageUrl: getImageUrl('categories/category-burgers.jpg') },
      { name: 'Fries & Sides', description: 'Crispy sides', imageUrl: null },
      { name: 'Beverages', description: 'Drinks', imageUrl: getImageUrl('categories/category-beverages.jpeg') },
    ];
    for (const cat of burgerCategories) {
      const category = await prisma.category.create({
        data: {
          ...cat,
          status: 'ACTIVE',
          shopId: shops[2].id,
      },
    });
      categoriesMap.set(`${shops[2].id}-${cat.name}`, category);
    }

    // Sushi House categories
    const sushiCategories = [
      { name: 'Sushi Rolls', description: 'Fresh sushi rolls', imageUrl: getImageUrl('categories/category-sushi.jpg') },
      { name: 'Sashimi', description: 'Fresh sashimi', imageUrl: null },
      { name: 'Appetizers', description: 'Japanese appetizers', imageUrl: null },
    ];
    for (const cat of sushiCategories) {
      const category = await prisma.category.create({
        data: {
          ...cat,
          status: 'ACTIVE',
          shopId: shops[3].id,
        },
      });
      categoriesMap.set(`${shops[3].id}-${cat.name}`, category);
    }

    // Coffee Corner categories
    const coffeeCategories = [
      { name: 'Coffee', description: 'Hot and cold coffee', imageUrl: getImageUrl('categories/category-coffee.jpeg') },
      { name: 'Pastries', description: 'Fresh baked pastries', imageUrl: null },
      { name: 'Tea', description: 'Premium teas', imageUrl: null },
    ];
    for (const cat of coffeeCategories) {
      const category = await prisma.category.create({
      data: {
          ...cat,
        status: 'ACTIVE',
          shopId: shops[4].id,
      },
    });
      categoriesMap.set(`${shops[4].id}-${cat.name}`, category);
    }

    // Bakery Bliss categories
    const bakeryCategories = [
      { name: 'Bread', description: 'Fresh baked bread', imageUrl: getImageUrl('categories/category-bakery.jpg') },
      { name: 'Pastries', description: 'Sweet pastries', imageUrl: null },
      { name: 'Cakes', description: 'Custom cakes', imageUrl: getImageUrl('categories/category-desserts.jpg') },
    ];
    for (const cat of bakeryCategories) {
      const category = await prisma.category.create({
      data: {
          ...cat,
        status: 'ACTIVE',
          shopId: shops[6].id,
      },
    });
      categoriesMap.set(`${shops[6].id}-${cat.name}`, category);
    }

    // Mega Retail Store categories - comprehensive retail categories
    const retailCategories = [
      { name: 'Electronics', description: 'Smartphones, laptops, tablets, and accessories', imageUrl: null },
      { name: 'Clothing & Fashion', description: 'Men\'s, women\'s, and kids clothing', imageUrl: null },
      { name: 'Home & Garden', description: 'Furniture, decor, and garden supplies', imageUrl: null },
      { name: 'Sports & Outdoors', description: 'Sports equipment and outdoor gear', imageUrl: null },
      { name: 'Books & Media', description: 'Books, movies, music, and games', imageUrl: null },
      { name: 'Beauty & Personal Care', description: 'Cosmetics, skincare, and grooming products', imageUrl: null },
      { name: 'Toys & Games', description: 'Toys, board games, and puzzles', imageUrl: null },
      { name: 'Automotive', description: 'Car accessories and parts', imageUrl: null },
    ];
    for (const cat of retailCategories) {
      const category = await prisma.category.create({
      data: {
          ...cat,
        status: 'ACTIVE',
          shopId: shops[10].id, // Mega Retail Store is the 11th shop (index 10)
        },
      });
      categoriesMap.set(`${shops[10].id}-${cat.name}`, category);
    }

    console.log('Created categories');

    // Create products
    const products = [];

    // Pizza Palace products
    const pizzaProducts = [
      { name: 'Margherita Pizza', description: 'Classic pizza with tomato sauce, mozzarella, and fresh basil', price: 14.99, categoryName: 'Pizza', imageUrl: getImageUrl('products/product-margherita-pizza.jpg'), tags: ['vegetarian', 'classic', 'italian'], rating: 4.6, ratingCount: 45 },
      { name: 'Pepperoni Pizza', description: 'Classic pizza with tomato sauce, mozzarella, and pepperoni', price: 16.99, categoryName: 'Pizza', imageUrl: getImageUrl('products/product-pepperoni-pizza.jpg'), tags: ['meat', 'classic', 'popular'], rating: 4.7, ratingCount: 62 },
      { name: 'Veggie Pizza', description: 'Loaded with fresh vegetables and herbs', price: 15.99, categoryName: 'Pizza', imageUrl: getImageUrl('products/product-veggie-pizza.jpg'), tags: ['vegetarian', 'healthy'], rating: 4.5, ratingCount: 38 },
      { name: 'Hawaiian Pizza', description: 'Ham, pineapple, and mozzarella', price: 17.99, categoryName: 'Pizza', imageUrl: getImageUrl('products/product-hawaiian-pizza.jpg'), tags: ['meat', 'sweet'], rating: 4.4, ratingCount: 29 },
      { name: 'Meat Lovers Pizza', description: 'Pepperoni, sausage, ham, and bacon', price: 19.99, categoryName: 'Pizza', imageUrl: getImageUrl('products/product-meat-lovers-pizza.jpg'), tags: ['meat', 'popular'], rating: 4.8, ratingCount: 71 },
      { name: 'Cheese Pizza', description: 'Golden mozzarella over rich tomato sauce', price: 13.99, categoryName: 'Pizza', imageUrl: getImageUrl('products/product-cheese-pizza.jpg'), tags: ['vegetarian', 'classic'], rating: 4.5, ratingCount: 34 },
      { name: 'Supreme Pizza', description: 'Loaded with pepperoni, sausage, peppers, onions, and olives', price: 18.99, categoryName: 'Pizza', imageUrl: getImageUrl('products/product-supreme-pizza.jpg'), tags: ['meat', 'loaded'], rating: 4.7, ratingCount: 58 },
      { name: 'BBQ Chicken Pizza', description: 'Grilled chicken, BBQ sauce, red onions, and cilantro', price: 18.49, categoryName: 'Pizza', imageUrl: getImageUrl('products/product-bbq-chicken-pizza.jpg'), tags: ['meat', 'bbq'], rating: 4.6, ratingCount: 47 },
      { name: 'Coca Cola', description: 'Classic refreshing cola drink', price: 2.99, categoryName: 'Beverages', imageUrl: getImageUrl('products/product-coca-cola.jpeg'), tags: ['drink', 'cola'], rating: 4.3, ratingCount: 23 },
      { name: 'Pepsi', description: 'Refreshing cola drink', price: 2.99, categoryName: 'Beverages', imageUrl: getImageUrl('products/product-pepsi.jpg'), tags: ['drink'], rating: 4.2, ratingCount: 15 },
    ];

    for (const prod of pizzaProducts) {
      const category = categoriesMap.get(`${shops[0].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
          data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
            inStock: true,
            stockQuantity: Math.floor(Math.random() * 100) + 20,
            isFeatured: prod.categoryName === 'Pizza',
            isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[0].id,
          },
        });
        products.push(product);
      }
    }

    // Fresh Market products
    const groceryProducts = [
      { name: 'Fresh Bananas', description: 'Ripe yellow bananas, perfect for snacking', price: 1.99, categoryName: 'Fresh Produce', imageUrl: getImageUrl('products/product-fresh-bananas.jpg'), tags: ['fruit', 'healthy'], rating: 4.4, ratingCount: 18 },
      { name: 'Red Apples', description: 'Crisp and sweet red apples', price: 2.49, categoryName: 'Fresh Produce', imageUrl: getImageUrl('products/product-apples.jpg'), tags: ['fruit', 'healthy'], rating: 4.5, ratingCount: 24 },
      { name: 'Fresh Bread', description: 'Artisan bread, baked daily', price: 3.99, categoryName: 'Pantry Staples', imageUrl: getImageUrl('products/product-bread.jpg'), tags: ['bread', 'fresh'], rating: 4.6, ratingCount: 31 },
      { name: 'Whole Milk', description: 'Fresh whole milk, 1 gallon', price: 4.99, categoryName: 'Dairy', imageUrl: getImageUrl('products/product-milk.jpg'), tags: ['dairy', 'fresh'], rating: 4.5, ratingCount: 42 },
      { name: 'Fresh Eggs', description: 'Farm fresh eggs, 12 count', price: 3.49, categoryName: 'Dairy', imageUrl: getImageUrl('products/product-eggs.jpg'), tags: ['dairy', 'protein'], rating: 4.7, ratingCount: 56 },
      { name: 'Tomatoes', description: 'Fresh red tomatoes', price: 2.99, categoryName: 'Fresh Produce', imageUrl: getImageUrl('products/product-tomatoes.jpg'), tags: ['vegetable', 'fresh'], rating: 4.4, ratingCount: 19 },
      { name: 'Chicken Breast', description: 'Fresh boneless chicken breast', price: 8.99, categoryName: 'Meat & Seafood', imageUrl: getImageUrl('products/product-chicken-breast.jpg'), tags: ['meat', 'protein'], rating: 4.6, ratingCount: 35 },
      { name: 'Rice', description: 'Premium long grain rice, 5lb bag', price: 5.99, categoryName: 'Pantry Staples', imageUrl: getImageUrl('products/product-rice.jpg'), tags: ['grain', 'staple'], rating: 4.5, ratingCount: 42 },
    ];

    for (const prod of groceryProducts) {
      const category = categoriesMap.get(`${shops[1].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
          data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
            inStock: true,
            stockQuantity: Math.floor(Math.random() * 200) + 50,
            isFeatured: prod.categoryName === 'Fresh Produce',
            isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[1].id,
      },
    });
        products.push(product);
      }
    }

    // Burger King products
    const burgerProducts = [
      { name: 'Classic Burger', description: 'Juicy beef patty with lettuce, tomato, and special sauce', price: 8.99, categoryName: 'Burgers', imageUrl: getImageUrl('products/product-classic-burger.jpg'), tags: ['meat', 'popular'], rating: 4.6, ratingCount: 89 },
      { name: 'Cheese Burger', description: 'Classic burger with melted cheese', price: 9.99, categoryName: 'Burgers', imageUrl: getImageUrl('products/product-cheese-burger.jpg'), tags: ['meat', 'cheese'], rating: 4.7, ratingCount: 112 },
      { name: 'Bacon Burger', description: 'Burger with crispy bacon and cheese', price: 11.99, categoryName: 'Burgers', imageUrl: getImageUrl('products/product-bacon-burger.jpg'), tags: ['meat', 'bacon'], rating: 4.8, ratingCount: 95 },
      { name: 'Double Burger', description: 'Two beef patties with double cheese and special sauce', price: 12.99, categoryName: 'Burgers', imageUrl: getImageUrl('products/product-double-burger.jpg'), tags: ['meat', 'double'], rating: 4.7, ratingCount: 84 },
      { name: 'Veggie Burger', description: 'Plant-based patty with fresh veggies and aioli', price: 10.49, categoryName: 'Burgers', imageUrl: getImageUrl('products/product-veggie-burger.jpg'), tags: ['vegetarian', 'healthy'], rating: 4.5, ratingCount: 51 },
      { name: 'French Fries', description: 'Crispy golden fries', price: 3.99, categoryName: 'Fries & Sides', imageUrl: getImageUrl('products/product-fries.jpg'), tags: ['side', 'popular'], rating: 4.5, ratingCount: 67 },
    ];

    for (const prod of burgerProducts) {
      const category = categoriesMap.get(`${shops[2].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
      data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
        inStock: true,
            stockQuantity: Math.floor(Math.random() * 100) + 30,
            isFeatured: prod.categoryName === 'Burgers',
        isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[2].id,
      },
    });
        products.push(product);
      }
    }

    // Sushi House products
    const sushiProducts = [
      { name: 'Salmon Roll', description: 'Fresh salmon with avocado and cucumber', price: 12.99, categoryName: 'Sushi Rolls', imageUrl: getImageUrl('products/product-salmon-roll.jpg'), tags: ['fish', 'popular'], rating: 4.8, ratingCount: 54 },
      { name: 'Tuna Roll', description: 'Fresh tuna with cucumber and avocado', price: 13.99, categoryName: 'Sushi Rolls', imageUrl: getImageUrl('products/product-tuna-roll.jpg'), tags: ['fish', 'fresh'], rating: 4.7, ratingCount: 42 },
      { name: 'California Roll', description: 'Crab, avocado, and cucumber', price: 10.99, categoryName: 'Sushi Rolls', imageUrl: getImageUrl('products/product-california-roll.jpg'), tags: ['popular', 'vegetarian'], rating: 4.6, ratingCount: 48 },
      { name: 'Dragon Roll', description: 'Eel, cucumber, and avocado topped with eel sauce', price: 14.99, categoryName: 'Sushi Rolls', imageUrl: getImageUrl('products/product-dragon-roll.jpg'), tags: ['premium', 'eel'], rating: 4.9, ratingCount: 62 },
      { name: 'Sashimi Platter', description: 'Assorted premium sashimi cuts', price: 18.99, categoryName: 'Sashimi', imageUrl: getImageUrl('products/product-sashimi-platter.jpeg'), tags: ['premium', 'fresh'], rating: 4.9, ratingCount: 57 },
    ];

    for (const prod of sushiProducts) {
      const category = categoriesMap.get(`${shops[3].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
      data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
        inStock: true,
            stockQuantity: Math.floor(Math.random() * 50) + 15,
        isFeatured: true,
        isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[3].id,
      },
    });
        products.push(product);
      }
    }

    // Coffee Corner products
    const coffeeProducts = [
      { name: 'Espresso', description: 'Strong and bold espresso shot', price: 2.99, categoryName: 'Coffee', imageUrl: getImageUrl('products/product-espresso.jpg'), tags: ['coffee', 'strong'], rating: 4.5, ratingCount: 34 },
      { name: 'Americano', description: 'Smooth espresso diluted with hot water', price: 3.49, categoryName: 'Coffee', imageUrl: getImageUrl('products/product-americano.jpg'), tags: ['coffee', 'classic'], rating: 4.4, ratingCount: 28 },
      { name: 'Cappuccino', description: 'Espresso with steamed milk and foam', price: 4.49, categoryName: 'Coffee', imageUrl: getImageUrl('products/product-cappuccino.jpg'), tags: ['coffee', 'popular'], rating: 4.7, ratingCount: 58 },
      { name: 'Latte', description: 'Smooth espresso with steamed milk', price: 4.99, categoryName: 'Coffee', imageUrl: getImageUrl('products/product-latte.jpg'), tags: ['coffee', 'milk'], rating: 4.6, ratingCount: 47 },
      { name: 'Mocha', description: 'Chocolate flavored latte topped with whipped cream', price: 5.49, categoryName: 'Coffee', imageUrl: getImageUrl('products/product-mocha.jpg'), tags: ['coffee', 'chocolate'], rating: 4.6, ratingCount: 39 },
      { name: 'Croissant', description: 'Buttery and flaky croissant', price: 3.49, categoryName: 'Pastries', imageUrl: getImageUrl('products/product-croissant.jpg'), tags: ['pastry', 'popular'], rating: 4.5, ratingCount: 29 },
    ];

    for (const prod of coffeeProducts) {
      const category = categoriesMap.get(`${shops[4].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
      data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
        inStock: true,
            stockQuantity: Math.floor(Math.random() * 100) + 25,
            isFeatured: prod.categoryName === 'Coffee',
        isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[4].id,
      },
    });
        products.push(product);
      }
    }

    // Bakery Bliss products
    const bakeryProducts = [
      { name: 'Fresh Baguette', description: 'Crispy French baguette, baked daily', price: 2.99, categoryName: 'Bread', imageUrl: getImageUrl('products/product-baguette.png'), tags: ['bread', 'fresh'], rating: 4.6, ratingCount: 41 },
      { name: 'Chocolate Donut', description: 'Glazed donut with chocolate frosting', price: 2.49, categoryName: 'Pastries', imageUrl: getImageUrl('products/product-donut.jpg'), tags: ['sweet', 'popular'], rating: 4.7, ratingCount: 63 },
      { name: 'Cake Slice', description: 'Assorted cake slices', price: 4.99, categoryName: 'Cakes', imageUrl: getImageUrl('products/product-cake-slice.jpg'), tags: ['dessert', 'sweet'], rating: 4.8, ratingCount: 52 },
      { name: 'Chocolate Cookies', description: 'Fresh baked chocolate chip cookies', price: 3.99, categoryName: 'Pastries', imageUrl: getImageUrl('products/product-cookies.jpg'), tags: ['sweet', 'cookies'], rating: 4.6, ratingCount: 48 },
    ];

    for (const prod of bakeryProducts) {
      const category = categoriesMap.get(`${shops[6].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
      data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
        inStock: true,
            stockQuantity: Math.floor(Math.random() * 80) + 20,
        isFeatured: true,
        isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[6].id,
          },
        });
        products.push(product);
      }
    }

    // Chicken Grill products
    const chickenProducts = [
      { name: 'Fried Chicken', description: 'Crispy golden fried chicken, 4 pieces', price: 12.99, categoryName: 'Main Dishes', imageUrl: '/uploads/products/product-fried-chicken.jpg.png', tags: ['chicken', 'fried', 'popular'], rating: 4.7, ratingCount: 89 },
      { name: 'Chicken Wings', description: 'Spicy buffalo wings with ranch dip', price: 10.99, categoryName: 'Main Dishes', imageUrl: getImageUrl('products/product-chicken-wings.jpg'), tags: ['chicken', 'wings', 'spicy'], rating: 4.6, ratingCount: 67 },
      { name: 'French Fries', description: 'Crispy golden fries', price: 3.99, categoryName: 'Sides', imageUrl: getImageUrl('products/product-fries.jpg'), tags: ['side', 'popular'], rating: 4.5, ratingCount: 54 },
      { name: 'Coleslaw', description: 'Fresh coleslaw with creamy dressing', price: 2.99, categoryName: 'Sides', imageUrl: getImageUrl('products/product-coleslaw.jpg'), tags: ['side', 'vegetable'], rating: 4.3, ratingCount: 32 },
    ];

    // Create categories for Chicken Grill if they don't exist
    const chickenCategories = [
      { name: 'Main Dishes', description: 'Main chicken dishes', imageUrl: null },
      { name: 'Sides', description: 'Side dishes', imageUrl: null },
    ];
    for (const cat of chickenCategories) {
      const existingCategory = categoriesMap.get(`${shops[7].id}-${cat.name}`);
      if (!existingCategory) {
        const category = await prisma.category.create({
          data: {
            ...cat,
            status: 'ACTIVE',
            shopId: shops[7].id,
          },
        });
        categoriesMap.set(`${shops[7].id}-${cat.name}`, category);
      }
    }

    for (const prod of chickenProducts) {
      const category = categoriesMap.get(`${shops[7].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
          data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
            inStock: true,
            stockQuantity: Math.floor(Math.random() * 100) + 30,
            isFeatured: prod.categoryName === 'Main Dishes',
            isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[7].id,
          },
        });
        products.push(product);
      }
    }

    // Ice Cream Parlor products
    const iceCreamProducts = [
      { name: 'Ice Cream Sundae', description: 'Vanilla ice cream with hot fudge, whipped cream, and cherry', price: 6.99, categoryName: 'Ice Cream', imageUrl: getImageUrl('products/product-ice-cream-sundae.jpeg'), tags: ['dessert', 'sweet', 'popular'], rating: 4.8, ratingCount: 112 },
      { name: 'Chocolate Ice Cream', description: 'Rich chocolate ice cream, single scoop', price: 4.99, categoryName: 'Ice Cream', imageUrl: getImageUrl('products/product-chocolate-ice-cream.jpg'), tags: ['dessert', 'chocolate'], rating: 4.7, ratingCount: 89 },
      { name: 'Strawberry Ice Cream', description: 'Fresh strawberry ice cream, single scoop', price: 4.99, categoryName: 'Ice Cream', imageUrl: getImageUrl('products/product-strawberry-ice-cream.jpg'), tags: ['dessert', 'fruit'], rating: 4.6, ratingCount: 76 },
    ];

    // Create categories for Ice Cream Parlor if they don't exist
    const iceCreamCategories = [
      { name: 'Ice Cream', description: 'Premium ice cream flavors', imageUrl: null },
    ];
    for (const cat of iceCreamCategories) {
      const existingCategory = categoriesMap.get(`${shops[8].id}-${cat.name}`);
      if (!existingCategory) {
        const category = await prisma.category.create({
          data: {
            ...cat,
            status: 'ACTIVE',
            shopId: shops[8].id,
          },
        });
        categoriesMap.set(`${shops[8].id}-${cat.name}`, category);
      }
    }

    for (const prod of iceCreamProducts) {
      const category = categoriesMap.get(`${shops[8].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
          data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
            inStock: true,
            stockQuantity: Math.floor(Math.random() * 50) + 20,
            isFeatured: true,
            isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[8].id,
          },
        });
        products.push(product);
      }
    }

    // Fast Food Express products
    const fastFoodProducts = [
      { name: 'Classic Burger', description: 'Juicy beef patty with lettuce, tomato, and special sauce', price: 7.99, categoryName: 'Burgers', imageUrl: getImageUrl('products/product-classic-burger.jpg'), tags: ['meat', 'popular'], rating: 4.5, ratingCount: 95 },
      { name: 'French Fries', description: 'Crispy golden fries', price: 2.99, categoryName: 'Sides', imageUrl: getImageUrl('products/product-fries.jpg'), tags: ['side', 'popular'], rating: 4.4, ratingCount: 78 },
      { name: 'Garden Salad', description: 'Fresh mixed greens with vegetables and dressing', price: 5.99, categoryName: 'Salads', imageUrl: getImageUrl('products/product-salad.jpg'), tags: ['healthy', 'vegetable'], rating: 4.3, ratingCount: 45 },
      { name: 'Chicken Soup', description: 'Hearty chicken soup with vegetables', price: 4.99, categoryName: 'Soups', imageUrl: getImageUrl('products/product-soup.jpg'), tags: ['soup', 'warm'], rating: 4.5, ratingCount: 52 },
    ];

    // Create categories for Fast Food Express if they don't exist
    const fastFoodCategories = [
      { name: 'Burgers', description: 'Juicy burgers', imageUrl: null },
      { name: 'Sides', description: 'Side dishes', imageUrl: null },
      { name: 'Salads', description: 'Fresh salads', imageUrl: null },
      { name: 'Soups', description: 'Hot soups', imageUrl: null },
    ];
    for (const cat of fastFoodCategories) {
      const existingCategory = categoriesMap.get(`${shops[9].id}-${cat.name}`);
      if (!existingCategory) {
        const category = await prisma.category.create({
          data: {
            ...cat,
            status: 'ACTIVE',
            shopId: shops[9].id,
          },
        });
        categoriesMap.set(`${shops[9].id}-${cat.name}`, category);
      }
    }

    for (const prod of fastFoodProducts) {
      const category = categoriesMap.get(`${shops[9].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
          data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
            inStock: true,
            stockQuantity: Math.floor(Math.random() * 100) + 25,
            isFeatured: prod.categoryName === 'Burgers',
            isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[9].id,
          },
        });
        products.push(product);
      }
    }

    // Mega Retail Store products - comprehensive retail products
    const retailProducts = [
      // Electronics
      { name: 'Wireless Headphones', description: 'Premium noise-cancelling wireless headphones with 30-hour battery', price: 89.99, categoryName: 'Electronics', imageUrl: getImageUrl('products/product-wireless-headphones.jpg'), tags: ['electronics', 'audio', 'wireless'], rating: 4.7, ratingCount: 156 },
      { name: 'Smartphone Case', description: 'Protective case with screen protector included', price: 24.99, categoryName: 'Electronics', imageUrl: getImageUrl('products/product-smartphone-case.jpg'), tags: ['electronics', 'accessories', 'protection'], rating: 4.5, ratingCount: 89 },
      { name: 'USB-C Charging Cable', description: 'Fast charging cable, 6ft length, durable design', price: 12.99, categoryName: 'Electronics', imageUrl: getImageUrl('products/product-usb-cable.jpg'), tags: ['electronics', 'cable', 'charging'], rating: 4.6, ratingCount: 203 },
      { name: 'Bluetooth Speaker', description: 'Portable waterproof speaker with 360° sound', price: 49.99, categoryName: 'Electronics', imageUrl: getImageUrl('products/product-bluetooth-speaker.jpg'), tags: ['electronics', 'audio', 'portable'], rating: 4.8, ratingCount: 127 },
      
      // Clothing & Fashion
      { name: 'Classic T-Shirt', description: '100% cotton comfortable t-shirt, available in multiple colors', price: 19.99, categoryName: 'Clothing & Fashion', imageUrl: getImageUrl('products/product-t-shirt.jpg'), tags: ['clothing', 'casual', 'cotton'], rating: 4.4, ratingCount: 94 },
      { name: 'Denim Jeans', description: 'Classic fit denim jeans, multiple sizes available', price: 59.99, categoryName: 'Clothing & Fashion', imageUrl: getImageUrl('products/product-denim-jeans.jpg'), tags: ['clothing', 'denim', 'casual'], rating: 4.6, ratingCount: 78 },
      { name: 'Running Shoes', description: 'Lightweight running shoes with cushioned sole', price: 79.99, categoryName: 'Clothing & Fashion', imageUrl: getImageUrl('products/product-running-shoes.jpg'), tags: ['clothing', 'shoes', 'sports'], rating: 4.7, ratingCount: 145 },
      { name: 'Winter Jacket', description: 'Warm insulated winter jacket, water-resistant', price: 129.99, categoryName: 'Clothing & Fashion', imageUrl: getImageUrl('products/product-winter-jacket.jpg'), tags: ['clothing', 'winter', 'warm'], rating: 4.8, ratingCount: 112 },
      
      // Home & Garden
      { name: 'Throw Pillow Set', description: 'Set of 2 decorative throw pillows, various patterns', price: 29.99, categoryName: 'Home & Garden', imageUrl: getImageUrl('products/product-throw-pillow-set.jpg'), tags: ['home', 'decor', 'pillows'], rating: 4.5, ratingCount: 67 },
      { name: 'Garden Tool Set', description: 'Complete gardening tool set with trowel, pruner, and gloves', price: 39.99, categoryName: 'Home & Garden', imageUrl: getImageUrl('products/product-garden-tool-set.jpg'), tags: ['garden', 'tools', 'outdoor'], rating: 4.6, ratingCount: 83 },
      { name: 'LED Desk Lamp', description: 'Adjustable LED desk lamp with USB charging port', price: 34.99, categoryName: 'Home & Garden', imageUrl: null, tags: ['home', 'lighting', 'desk'], rating: 4.7, ratingCount: 98 },
      { name: 'Plant Pot Set', description: 'Set of 3 ceramic plant pots, various sizes', price: 24.99, categoryName: 'Home & Garden', imageUrl: null, tags: ['home', 'garden', 'pots'], rating: 4.4, ratingCount: 56 },
      
      // Sports & Outdoors
      { name: 'Yoga Mat', description: 'Non-slip yoga mat with carrying strap', price: 29.99, categoryName: 'Sports & Outdoors', imageUrl: null, tags: ['sports', 'yoga', 'fitness'], rating: 4.6, ratingCount: 124 },
      { name: 'Dumbbell Set', description: 'Adjustable dumbbell set, 5-25 lbs per dumbbell', price: 89.99, categoryName: 'Sports & Outdoors', imageUrl: null, tags: ['sports', 'fitness', 'weights'], rating: 4.7, ratingCount: 91 },
      { name: 'Camping Tent', description: '4-person camping tent, waterproof and easy setup', price: 149.99, categoryName: 'Sports & Outdoors', imageUrl: null, tags: ['outdoor', 'camping', 'tent'], rating: 4.8, ratingCount: 67 },
      { name: 'Water Bottle', description: 'Insulated stainless steel water bottle, 32oz', price: 19.99, categoryName: 'Sports & Outdoors', imageUrl: null, tags: ['sports', 'hydration', 'bottle'], rating: 4.5, ratingCount: 156 },
      
      // Books & Media
      { name: 'Bestselling Novel', description: 'Latest bestselling fiction novel, paperback edition', price: 14.99, categoryName: 'Books & Media', imageUrl: null, tags: ['books', 'fiction', 'novel'], rating: 4.6, ratingCount: 203 },
      { name: 'Board Game', description: 'Popular strategy board game for 2-4 players', price: 39.99, categoryName: 'Books & Media', imageUrl: null, tags: ['games', 'board', 'entertainment'], rating: 4.7, ratingCount: 89 },
      { name: 'Puzzle Set', description: '1000-piece jigsaw puzzle, various designs', price: 12.99, categoryName: 'Books & Media', imageUrl: null, tags: ['games', 'puzzle', 'entertainment'], rating: 4.5, ratingCount: 112 },
      { name: 'Cookbook', description: 'Comprehensive cookbook with 200+ recipes', price: 24.99, categoryName: 'Books & Media', imageUrl: null, tags: ['books', 'cooking', 'recipes'], rating: 4.8, ratingCount: 145 },
      
      // Beauty & Personal Care
      { name: 'Skincare Set', description: 'Complete skincare set with cleanser, toner, and moisturizer', price: 49.99, categoryName: 'Beauty & Personal Care', imageUrl: null, tags: ['beauty', 'skincare', 'set'], rating: 4.6, ratingCount: 178 },
      { name: 'Hair Care Bundle', description: 'Shampoo, conditioner, and hair mask bundle', price: 29.99, categoryName: 'Beauty & Personal Care', imageUrl: null, tags: ['beauty', 'hair', 'care'], rating: 4.5, ratingCount: 134 },
      { name: 'Makeup Brush Set', description: 'Professional makeup brush set, 12 pieces', price: 34.99, categoryName: 'Beauty & Personal Care', imageUrl: null, tags: ['beauty', 'makeup', 'brushes'], rating: 4.7, ratingCount: 98 },
      { name: 'Perfume Gift Set', description: 'Eau de parfum gift set, 3 fragrances', price: 59.99, categoryName: 'Beauty & Personal Care', imageUrl: null, tags: ['beauty', 'fragrance', 'gift'], rating: 4.8, ratingCount: 67 },
      
      // Toys & Games
      { name: 'Building Blocks Set', description: 'Educational building blocks, 200 pieces', price: 29.99, categoryName: 'Toys & Games', imageUrl: null, tags: ['toys', 'educational', 'blocks'], rating: 4.7, ratingCount: 156 },
      { name: 'Action Figure', description: 'Collectible action figure, detailed design', price: 19.99, categoryName: 'Toys & Games', imageUrl: null, tags: ['toys', 'action', 'collectible'], rating: 4.5, ratingCount: 89 },
      { name: 'Remote Control Car', description: 'RC car with 2.4GHz controller, rechargeable battery', price: 49.99, categoryName: 'Toys & Games', imageUrl: null, tags: ['toys', 'rc', 'car'], rating: 4.6, ratingCount: 112 },
      { name: 'Art Supplies Kit', description: 'Complete art supplies kit with paints, brushes, and canvas', price: 39.99, categoryName: 'Toys & Games', imageUrl: null, tags: ['toys', 'art', 'creative'], rating: 4.8, ratingCount: 78 },
      
      // Automotive
      { name: 'Car Phone Mount', description: 'Magnetic car phone mount, dashboard or vent mount', price: 14.99, categoryName: 'Automotive', imageUrl: null, tags: ['automotive', 'accessories', 'mount'], rating: 4.6, ratingCount: 203 },
      { name: 'Car Air Freshener', description: 'Long-lasting car air freshener, various scents', price: 4.99, categoryName: 'Automotive', imageUrl: null, tags: ['automotive', 'accessories', 'freshener'], rating: 4.4, ratingCount: 156 },
      { name: 'Tire Pressure Gauge', description: 'Digital tire pressure gauge with LCD display', price: 19.99, categoryName: 'Automotive', imageUrl: null, tags: ['automotive', 'tools', 'gauge'], rating: 4.7, ratingCount: 89 },
      { name: 'Car Cleaning Kit', description: 'Complete car cleaning kit with microfiber towels and cleaner', price: 24.99, categoryName: 'Automotive', imageUrl: null, tags: ['automotive', 'cleaning', 'kit'], rating: 4.6, ratingCount: 134 },
    ];

    for (const prod of retailProducts) {
      const category = categoriesMap.get(`${shops[10].id}-${prod.categoryName}`);
      if (category) {
        const product = await prisma.product.create({
          data: {
            name: prod.name,
            description: prod.description,
            price: prod.price,
            imageUrl: prod.imageUrl,
            images: prod.imageUrl ? [prod.imageUrl] : [],
            categoryName: prod.categoryName,
            categoryId: category.id,
            tags: prod.tags,
            inStock: true,
            stockQuantity: Math.floor(Math.random() * 100) + 20,
            isFeatured: Math.random() > 0.7, // Randomly feature some products
            isActive: true,
            rating: prod.rating,
            ratingCount: prod.ratingCount,
            shopId: shops[10].id,
          },
        });
        products.push(product);
      }
    }

    console.log(`Created ${products.length} products`);

    // Create addresses for customers
    const addresses = [];
    // Base coordinates near San Francisco for sample customer addresses
    const baseLat = 37.7749;
    const baseLng = -122.4194;

    for (let i = 0; i < customerUsers.length; i++) {
      const address = await prisma.address.create({
        data: {
          label: i === 0 ? 'Home' : i === 1 ? 'Work' : 'Apartment',
          fullAddress: `${100 + i * 10} Customer Street, Apt ${i + 1}`,
          latitude: baseLat + (i * 0.01),
          longitude: baseLng + (i * 0.01),
          isDefault: i === 0,
          userId: customerUsers[i].id,
        },
      });
      addresses.push(address);
    }

    console.log('Created customer addresses');

    // Create sample orders with different statuses
    const orders = [];
    const orderStatuses = [
      OrderStatus.PENDING,
      OrderStatus.ACCEPTED,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
      OrderStatus.IN_DELIVERY,
      OrderStatus.DELIVERED,
    ];

    // Create 15-20 orders
    for (let i = 0; i < 18; i++) {
      const customer = customerUsers[i % customerUsers.length];
      const shop = shops[i % shops.length];
      const address = addresses[i % addresses.length];
      const status = orderStatuses[i % orderStatuses.length];
      const deliveryPerson = status === OrderStatus.IN_DELIVERY || status === OrderStatus.DELIVERED
        ? deliveryUsers[i % deliveryUsers.length]
        : null;

      const orderNumber = `ORD-${Date.now()}-${i + 1}`;
      const subtotal = 25.0 + (i * 5);
      const deliveryFee = shop.deliveryFee;
      const serviceFee = subtotal * 0.05;
      const tax = subtotal * 0.08;
      const total = subtotal + deliveryFee + serviceFee + tax;

      const order = await prisma.order.create({
        data: {
          orderNumber,
          userId: customer.id,
          shopId: shop.id,
          shopName: shop.name,
          addressId: address.id,
          deliveryAddress: address.fullAddress,
          deliveryLatitude: address.latitude,
          deliveryLongitude: address.longitude,
          subtotal,
          deliveryFee,
          serviceFee,
          tax,
          total,
          paymentMethod: i % 2 === 0 ? PaymentMethod.CARD : PaymentMethod.CASH_ON_DELIVERY,
          status,
          deliveryPersonId: deliveryPerson?.id || null,
          estimatedDeliveryTime: new Date(Date.now() + 30 * 60 * 1000), // 30 minutes from now
          deliveredAt: status === OrderStatus.DELIVERED ? new Date(Date.now() - (i * 60 * 60 * 1000)) : null,
      },
    });

      // Add order items
      const shopProducts = products.filter(p => p.shopId === shop.id);
      if (shopProducts.length > 0) {
        const selectedProducts = shopProducts.slice(0, Math.min(3, shopProducts.length));
        for (const product of selectedProducts) {
          const quantity = Math.floor(Math.random() * 3) + 1;
          await prisma.orderItem.create({
            data: {
              orderId: order.id,
              productId: product.id,
              productName: product.name,
              productPrice: product.price,
              quantity,
              totalPrice: product.price * quantity,
            },
          });
        }
      }

      orders.push(order);
    }

    console.log(`Created ${orders.length} orders`);

    // Create reviews
    const reviews = [];
    for (let i = 0; i < 25; i++) {
      const customer = customerUsers[i % customerUsers.length];
      const shop = shops[i % shops.length];
      const ratings = [4, 4.5, 5, 4.5, 5, 4, 4.5, 5];
      const comments = [
        'Great food and fast delivery!',
        'Excellent service, will order again.',
        'Amazing quality, highly recommended!',
        'Good food but delivery was a bit slow.',
        'Perfect! Exactly as described.',
        'Very satisfied with my order.',
        'Great value for money.',
        'The best in town!',
      ];

      const review = await prisma.review.create({
        data: {
          userId: customer.id,
          shopId: shop.id,
          rating: ratings[i % ratings.length],
          comment: comments[i % comments.length],
        },
      });
      reviews.push(review);
    }

    console.log(`Created ${reviews.length} reviews`);

    console.log('✅ Seeding completed successfully!');
    console.log(`   - ${vendorUsers.length + customerUsers.length + deliveryUsers.length + 1} users`);
    console.log(`   - ${shops.length} shops`);
    console.log(`   - ${products.length} products`);
    console.log(`   - ${orders.length} orders`);
    console.log(`   - ${reviews.length} reviews`);
  } else {
    console.log('Shops already exist, skipping seed data creation');
    console.log('To reset, delete all data from the database first');
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

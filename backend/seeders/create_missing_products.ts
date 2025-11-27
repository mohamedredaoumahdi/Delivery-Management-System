import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Helper function to get image URL
const getImageUrl = (path: string | null): string | null => {
  if (!path) return null;
  return `/uploads/${path}`;
};

async function main() {
  console.log('Creating missing products for shops...\n');

  // Get shops
  const iceCreamParlor = await prisma.shop.findFirst({
    where: { name: 'Ice Cream Parlor' },
    select: { id: true, name: true },
  });

  const chickenGrill = await prisma.shop.findFirst({
    where: { name: 'Chicken Grill' },
    select: { id: true, name: true },
  });

  const fastFoodExpress = await prisma.shop.findFirst({
    where: { name: 'Fast Food Express' },
    select: { id: true, name: true },
  });

  const pharmacyPlus = await prisma.shop.findFirst({
    where: { name: 'Pharmacy Plus' },
    select: { id: true, name: true },
  });

  if (!iceCreamParlor || !chickenGrill || !fastFoodExpress || !pharmacyPlus) {
    console.error('❌ Could not find all required shops');
    return;
  }

  let createdCount = 0;

  // Ice Cream Parlor products
  console.log(`\n🏪 Creating products for ${iceCreamParlor.name}...`);
  
  // Get or create Ice Cream category
  let iceCreamCategory = await prisma.category.findFirst({
    where: {
      shopId: iceCreamParlor.id,
      name: 'Ice Cream',
    },
  });

  if (!iceCreamCategory) {
    iceCreamCategory = await prisma.category.create({
      data: {
        name: 'Ice Cream',
        description: 'Premium ice cream flavors',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: iceCreamParlor.id,
      },
    });
    console.log('  ✅ Created "Ice Cream" category');
  }

  const iceCreamProducts = [
    { name: 'Ice Cream Sundae', description: 'Vanilla ice cream with hot fudge, whipped cream, and cherry', price: 6.99, imageUrl: getImageUrl('products/product-ice-cream-sundae.jpeg'), tags: ['dessert', 'sweet', 'popular'], rating: 4.8, ratingCount: 112 },
    { name: 'Chocolate Ice Cream', description: 'Rich chocolate ice cream, single scoop', price: 4.99, imageUrl: getImageUrl('products/product-chocolate-ice-cream.jpg'), tags: ['dessert', 'chocolate'], rating: 4.7, ratingCount: 89 },
    { name: 'Strawberry Ice Cream', description: 'Fresh strawberry ice cream, single scoop', price: 4.99, imageUrl: getImageUrl('products/product-strawberry-ice-cream.jpg'), tags: ['dessert', 'fruit'], rating: 4.6, ratingCount: 76 },
  ];

  for (const prod of iceCreamProducts) {
    const existing = await prisma.product.findFirst({
      where: {
        shopId: iceCreamParlor.id,
        name: prod.name,
      },
    });

    if (!existing) {
      await prisma.product.create({
        data: {
          name: prod.name,
          description: prod.description,
          price: prod.price,
          imageUrl: prod.imageUrl,
          images: prod.imageUrl ? [prod.imageUrl] : [],
          categoryName: 'Ice Cream',
          categoryId: iceCreamCategory.id,
          tags: prod.tags,
          inStock: true,
          stockQuantity: Math.floor(Math.random() * 50) + 20,
          isFeatured: true,
          isActive: true,
          rating: prod.rating,
          ratingCount: prod.ratingCount,
          shopId: iceCreamParlor.id,
        },
      });
      createdCount++;
      console.log(`  ✅ Created "${prod.name}"`);
    } else {
      console.log(`  ⚠️  "${prod.name}" already exists`);
    }
  }

  // Chicken Grill products
  console.log(`\n🏪 Creating products for ${chickenGrill.name}...`);
  
  // Get or create categories
  let mainDishesCategory = await prisma.category.findFirst({
    where: {
      shopId: chickenGrill.id,
      name: 'Main Dishes',
    },
  });

  if (!mainDishesCategory) {
    mainDishesCategory = await prisma.category.create({
      data: {
        name: 'Main Dishes',
        description: 'Main chicken dishes',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: chickenGrill.id,
      },
    });
    console.log('  ✅ Created "Main Dishes" category');
  }

  let sidesCategory = await prisma.category.findFirst({
    where: {
      shopId: chickenGrill.id,
      name: 'Sides',
    },
  });

  if (!sidesCategory) {
    sidesCategory = await prisma.category.create({
      data: {
        name: 'Sides',
        description: 'Side dishes',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: chickenGrill.id,
      },
    });
    console.log('  ✅ Created "Sides" category');
  }

  const chickenProducts = [
    { name: 'Fried Chicken', description: 'Crispy golden fried chicken, 4 pieces', price: 12.99, categoryName: 'Main Dishes', categoryId: mainDishesCategory.id, imageUrl: '/uploads/products/product-fried-chicken.jpg.png', tags: ['chicken', 'fried', 'popular'], rating: 4.7, ratingCount: 89 },
    { name: 'Chicken Wings', description: 'Spicy buffalo wings with ranch dip', price: 10.99, categoryName: 'Main Dishes', categoryId: mainDishesCategory.id, imageUrl: getImageUrl('products/product-chicken-wings.jpg'), tags: ['chicken', 'wings', 'spicy'], rating: 4.6, ratingCount: 67 },
    { name: 'French Fries', description: 'Crispy golden fries', price: 3.99, categoryName: 'Sides', categoryId: sidesCategory.id, imageUrl: getImageUrl('products/product-fries.jpg'), tags: ['side', 'popular'], rating: 4.5, ratingCount: 54 },
    { name: 'Coleslaw', description: 'Fresh coleslaw with creamy dressing', price: 2.99, categoryName: 'Sides', categoryId: sidesCategory.id, imageUrl: getImageUrl('products/product-coleslaw.jpg'), tags: ['side', 'vegetable'], rating: 4.3, ratingCount: 32 },
  ];

  for (const prod of chickenProducts) {
    const existing = await prisma.product.findFirst({
      where: {
        shopId: chickenGrill.id,
        name: prod.name,
      },
    });

    if (!existing) {
      await prisma.product.create({
        data: {
          name: prod.name,
          description: prod.description,
          price: prod.price,
          imageUrl: prod.imageUrl,
          images: prod.imageUrl ? [prod.imageUrl] : [],
          categoryName: prod.categoryName,
          categoryId: prod.categoryId,
          tags: prod.tags,
          inStock: true,
          stockQuantity: Math.floor(Math.random() * 100) + 30,
          isFeatured: prod.categoryName === 'Main Dishes',
          isActive: true,
          rating: prod.rating,
          ratingCount: prod.ratingCount,
          shopId: chickenGrill.id,
        },
      });
      createdCount++;
      console.log(`  ✅ Created "${prod.name}"`);
    } else {
      console.log(`  ⚠️  "${prod.name}" already exists`);
    }
  }

  // Fast Food Express products
  console.log(`\n🏪 Creating products for ${fastFoodExpress.name}...`);
  
  // Get or create categories
  let burgersCategory = await prisma.category.findFirst({
    where: {
      shopId: fastFoodExpress.id,
      name: 'Burgers',
    },
  });

  if (!burgersCategory) {
    burgersCategory = await prisma.category.create({
      data: {
        name: 'Burgers',
        description: 'Juicy burgers',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: fastFoodExpress.id,
      },
    });
    console.log('  ✅ Created "Burgers" category');
  }

  let fastFoodSidesCategory = await prisma.category.findFirst({
    where: {
      shopId: fastFoodExpress.id,
      name: 'Sides',
    },
  });

  if (!fastFoodSidesCategory) {
    fastFoodSidesCategory = await prisma.category.create({
      data: {
        name: 'Sides',
        description: 'Side dishes',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: fastFoodExpress.id,
      },
    });
    console.log('  ✅ Created "Sides" category');
  }

  let saladsCategory = await prisma.category.findFirst({
    where: {
      shopId: fastFoodExpress.id,
      name: 'Salads',
    },
  });

  if (!saladsCategory) {
    saladsCategory = await prisma.category.create({
      data: {
        name: 'Salads',
        description: 'Fresh salads',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: fastFoodExpress.id,
      },
    });
    console.log('  ✅ Created "Salads" category');
  }

  let soupsCategory = await prisma.category.findFirst({
    where: {
      shopId: fastFoodExpress.id,
      name: 'Soups',
    },
  });

  if (!soupsCategory) {
    soupsCategory = await prisma.category.create({
      data: {
        name: 'Soups',
        description: 'Hot soups',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: fastFoodExpress.id,
      },
    });
    console.log('  ✅ Created "Soups" category');
  }

  const fastFoodProducts = [
    { name: 'Classic Burger', description: 'Juicy beef patty with lettuce, tomato, and special sauce', price: 7.99, categoryName: 'Burgers', categoryId: burgersCategory.id, imageUrl: getImageUrl('products/product-classic-burger.jpg'), tags: ['meat', 'popular'], rating: 4.5, ratingCount: 95 },
    { name: 'French Fries', description: 'Crispy golden fries', price: 2.99, categoryName: 'Sides', categoryId: fastFoodSidesCategory.id, imageUrl: getImageUrl('products/product-fries.jpg'), tags: ['side', 'popular'], rating: 4.4, ratingCount: 78 },
    { name: 'Garden Salad', description: 'Fresh mixed greens with vegetables and dressing', price: 5.99, categoryName: 'Salads', categoryId: saladsCategory.id, imageUrl: getImageUrl('products/product-salad.jpg'), tags: ['healthy', 'vegetable'], rating: 4.3, ratingCount: 45 },
    { name: 'Chicken Soup', description: 'Hearty chicken soup with vegetables', price: 4.99, categoryName: 'Soups', categoryId: soupsCategory.id, imageUrl: getImageUrl('products/product-soup.jpg'), tags: ['soup', 'warm'], rating: 4.5, ratingCount: 52 },
  ];

  for (const prod of fastFoodProducts) {
    const existing = await prisma.product.findFirst({
      where: {
        shopId: fastFoodExpress.id,
        name: prod.name,
      },
    });

    if (!existing) {
      await prisma.product.create({
        data: {
          name: prod.name,
          description: prod.description,
          price: prod.price,
          imageUrl: prod.imageUrl,
          images: prod.imageUrl ? [prod.imageUrl] : [],
          categoryName: prod.categoryName,
          categoryId: prod.categoryId,
          tags: prod.tags,
          inStock: true,
          stockQuantity: Math.floor(Math.random() * 100) + 25,
          isFeatured: prod.categoryName === 'Burgers',
          isActive: true,
          rating: prod.rating,
          ratingCount: prod.ratingCount,
          shopId: fastFoodExpress.id,
        },
      });
      createdCount++;
      console.log(`  ✅ Created "${prod.name}"`);
    } else {
      console.log(`  ⚠️  "${prod.name}" already exists`);
    }
  }

  // Pharmacy Plus products
  console.log(`\n🏪 Creating products for ${pharmacyPlus.name}...`);
  
  // Get or create categories
  let prescriptionsCategory = await prisma.category.findFirst({
    where: {
      shopId: pharmacyPlus.id,
      name: 'Prescriptions',
    },
  });

  if (!prescriptionsCategory) {
    prescriptionsCategory = await prisma.category.create({
      data: {
        name: 'Prescriptions',
        description: 'Prescription medications',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: pharmacyPlus.id,
      },
    });
    console.log('  ✅ Created "Prescriptions" category');
  }

  let healthProductsCategory = await prisma.category.findFirst({
    where: {
      shopId: pharmacyPlus.id,
      name: 'Health Products',
    },
  });

  if (!healthProductsCategory) {
    healthProductsCategory = await prisma.category.create({
      data: {
        name: 'Health Products',
        description: 'Health and wellness products',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: pharmacyPlus.id,
      },
    });
    console.log('  ✅ Created "Health Products" category');
  }

  let vitaminsCategory = await prisma.category.findFirst({
    where: {
      shopId: pharmacyPlus.id,
      name: 'Vitamins & Supplements',
    },
  });

  if (!vitaminsCategory) {
    vitaminsCategory = await prisma.category.create({
      data: {
        name: 'Vitamins & Supplements',
        description: 'Vitamins and dietary supplements',
        imageUrl: null,
        status: 'ACTIVE',
        shopId: pharmacyPlus.id,
      },
    });
    console.log('  ✅ Created "Vitamins & Supplements" category');
  }

  const pharmacyProducts = [
    { name: 'Pain Relief Tablets', description: 'Fast-acting pain relief, 20 tablets', price: 8.99, categoryName: 'Health Products', categoryId: healthProductsCategory.id, imageUrl: null, tags: ['pain', 'relief', 'medicine'], rating: 4.6, ratingCount: 89 },
    { name: 'Multivitamin Complex', description: 'Daily multivitamin with essential nutrients, 60 tablets', price: 12.99, categoryName: 'Vitamins & Supplements', categoryId: vitaminsCategory.id, imageUrl: null, tags: ['vitamins', 'health', 'daily'], rating: 4.7, ratingCount: 124 },
    { name: 'Vitamin C Tablets', description: 'Immune support vitamin C, 100 tablets', price: 9.99, categoryName: 'Vitamins & Supplements', categoryId: vitaminsCategory.id, imageUrl: null, tags: ['vitamin-c', 'immune', 'health'], rating: 4.5, ratingCount: 98 },
    { name: 'Bandages & First Aid Kit', description: 'Complete first aid kit with bandages and antiseptic', price: 15.99, categoryName: 'Health Products', categoryId: healthProductsCategory.id, imageUrl: null, tags: ['first-aid', 'bandages', 'emergency'], rating: 4.8, ratingCount: 67 },
    { name: 'Thermometer Digital', description: 'Digital thermometer for accurate temperature reading', price: 14.99, categoryName: 'Health Products', categoryId: healthProductsCategory.id, imageUrl: null, tags: ['thermometer', 'health', 'monitoring'], rating: 4.6, ratingCount: 45 },
    { name: 'Hand Sanitizer', description: 'Alcohol-based hand sanitizer, 500ml', price: 6.99, categoryName: 'Health Products', categoryId: healthProductsCategory.id, imageUrl: null, tags: ['sanitizer', 'hygiene', 'clean'], rating: 4.4, ratingCount: 156 },
  ];

  for (const prod of pharmacyProducts) {
    const existing = await prisma.product.findFirst({
      where: {
        shopId: pharmacyPlus.id,
        name: prod.name,
      },
    });

    if (!existing) {
      await prisma.product.create({
        data: {
          name: prod.name,
          description: prod.description,
          price: prod.price,
          imageUrl: prod.imageUrl,
          images: prod.imageUrl ? [prod.imageUrl] : [],
          categoryName: prod.categoryName,
          categoryId: prod.categoryId,
          tags: prod.tags,
          inStock: true,
          stockQuantity: Math.floor(Math.random() * 100) + 30,
          isFeatured: prod.categoryName === 'Health Products',
          isActive: true,
          rating: prod.rating,
          ratingCount: prod.ratingCount,
          shopId: pharmacyPlus.id,
        },
      });
      createdCount++;
      console.log(`  ✅ Created "${prod.name}"`);
    } else {
      console.log(`  ⚠️  "${prod.name}" already exists`);
    }
  }

  console.log(`\n✅ Successfully created ${createdCount} products!`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


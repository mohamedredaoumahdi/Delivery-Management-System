import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Helper function to get image URL
const getImageUrl = (path: string | null): string | null => {
  if (!path) return null;
  return `/uploads/${path}`;
};

async function main() {
  console.log('Updating category images...');

  // Category image mappings - format: { shopName: { categoryName: imagePath } }
  const categoryImageMap: Record<string, Record<string, string>> = {
    "Mario's Pizza Palace": {
      'Pizza': 'categories/category-pizza.png',
      'Beverages': 'categories/category-beverages.jpeg',
    },
    'Burger King Express': {
      'Burgers': 'categories/category-burgers.jpg',
      'Beverages': 'categories/category-beverages.jpeg',
    },
    'Sushi House': {
      'Sushi Rolls': 'categories/category-sushi.jpg',
    },
    'Coffee Corner': {
      'Coffee': 'categories/category-coffee.jpeg',
    },
    'Fresh Market': {
      'Fresh Produce': 'categories/category-grocery.png',
    },
    'Bakery Bliss': {
      'Bread': 'categories/category-bakery.jpg',
      'Cakes': 'categories/category-desserts.jpg',
    },
  };

  let updatedCount = 0;

  // Get all shops
  const shops = await prisma.shop.findMany({
    select: { id: true, name: true },
  });

  // Update each category
  for (const shop of shops) {
    const shopCategories = categoryImageMap[shop.name];
    if (!shopCategories) continue;

    for (const [categoryName, imagePath] of Object.entries(shopCategories)) {
      const imageUrl = getImageUrl(imagePath);
      if (!imageUrl) continue;

      const result = await prisma.category.updateMany({
        where: {
          shopId: shop.id,
          name: categoryName,
        },
        data: {
          imageUrl: imageUrl,
        },
      });

      if (result.count > 0) {
        updatedCount += result.count;
        console.log(`  ✅ Updated "${categoryName}" in "${shop.name}" with ${imagePath}`);
      } else {
        console.warn(`  ⚠️ No matching category found: "${categoryName}" in "${shop.name}"`);
      }
    }
  }

  console.log(`\n✅ Category images updated successfully!`);
  console.log(`   Updated ${updatedCount} categories with images`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


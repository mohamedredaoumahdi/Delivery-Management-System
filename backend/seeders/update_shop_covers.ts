import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const getImageUrl = (path: string | null): string | null => {
  if (!path) return null;
  return `/uploads/${path}`;
};

async function main() {
  console.log('Updating shop cover images...');

  const coverImageMap: Record<string, string> = {
    "Mario's Pizza Palace": 'shops/covers/cover-pizza-palace.jpg',
    'Fresh Market': 'shops/covers/cover-fresh-market.png',
    'Burger King Express': 'shops/covers/cover-burger-king.jpg',
    'Sushi House': 'shops/covers/cover-sushi-house.jpg',
    'Coffee Corner': 'shops/covers/cover-coffee-corner.jpg',
    'Pharmacy Plus': 'shops/covers/cover-pharmacy-plus.jpg',
    'Bakery Bliss': 'shops/covers/cover-bakery-bliss.jpg',
    'Chicken Grill': 'shops/covers/cover-chicken-grill.jpg',
    'Ice Cream Parlor': 'shops/covers/cover-ice-cream-parlor.jpg',
    'Fast Food Express': 'shops/covers/cover-fast-food.jpg',
    'Mega Retail Store': 'shops/covers/cover-mega-retail.jpg',
  };

  let updatedCount = 0;

  for (const [shopName, coverPath] of Object.entries(coverImageMap)) {
    const result = await prisma.shop.updateMany({
      where: { name: shopName },
      data: {
        coverImageUrl: getImageUrl(coverPath),
      },
    });

    if (result.count > 0) {
      updatedCount += result.count;
      console.log(`  ✅ Updated "${shopName}" with ${coverPath}`);
    } else {
      console.warn(`  ⚠️ No matching shop found for "${shopName}"`);
    }
  }

  console.log(`\n✅ Cover image update complete (${updatedCount} shops updated)`);
}

main()
  .catch((error) => {
    console.error('Failed to update shop cover images:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('📦 Checking all products and their images...\n');

  // Get all shops
  const shops = await prisma.shop.findMany({
    orderBy: { name: 'asc' },
    select: { id: true, name: true },
  });

  let totalProducts = 0;
  let productsWithImages = 0;
  let productsWithoutImages = 0;

  for (const shop of shops) {
    const products = await prisma.product.findMany({
      where: { shopId: shop.id },
      orderBy: { name: 'asc' },
      select: {
        name: true,
        imageUrl: true,
        categoryName: true,
      },
    });

    if (products.length === 0) continue;

    console.log(`\n🏪 ${shop.name} (${products.length} products):`);
    console.log('─'.repeat(80));

    for (const product of products) {
      totalProducts++;
      const hasImage = product.imageUrl !== null && product.imageUrl !== '';
      const status = hasImage ? '✅' : '❌';
      const imageInfo = hasImage ? product.imageUrl : 'NO IMAGE';
      
      console.log(`  ${status} ${product.name.padEnd(35)} | ${product.categoryName.padEnd(20)} | ${imageInfo}`);
      
      if (hasImage) {
        productsWithImages++;
      } else {
        productsWithoutImages++;
      }
    }
  }

  console.log('\n' + '='.repeat(80));
  console.log('📊 SUMMARY:');
  console.log('='.repeat(80));
  console.log(`  Total Products:        ${totalProducts}`);
  console.log(`  ✅ With Images:        ${productsWithImages} (${Math.round(productsWithImages / totalProducts * 100)}%)`);
  console.log(`  ❌ Without Images:     ${productsWithoutImages} (${Math.round(productsWithoutImages / totalProducts * 100)}%)`);
  console.log('='.repeat(80));
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Updating ALL shops to San Francisco coordinates for nearby shops section...\n');

  const baseLat = 37.7749;
  const baseLng = -122.4194;

  // Update all shops
  const shops = await prisma.shop.findMany();

  console.log(`Found ${shops.length} shops. Updating shop coordinates...`);

  // Spread all shops around the base point but keep them within a few km
  for (let i = 0; i < shops.length; i++) {
    const shop = shops[i];
    const offset = (i % 10) * 0.01; // up to ~1km offset

    await prisma.shop.update({
      where: { id: shop.id },
      data: {
        latitude: baseLat + offset,
        longitude: baseLng + offset,
      },
    });
  }

  // Update all customer addresses to be close to the same base point
  const addresses = await prisma.address.findMany();
  console.log(`Found ${addresses.length} addresses. Updating address coordinates...`);

  for (let i = 0; i < addresses.length; i++) {
    const address = addresses[i];
    const offset = (i % 10) * 0.01;

    await prisma.address.update({
      where: { id: address.id },
      data: {
        latitude: baseLat + offset,
        longitude: baseLng + offset,
      },
    });
  }

  console.log('\n✅ Nearby shops and addresses update complete!');
  console.log('   All shops and customer addresses are now located near the San Francisco base location');
}

main()
  .catch((error) => {
    console.error('Failed to update nearby shops:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


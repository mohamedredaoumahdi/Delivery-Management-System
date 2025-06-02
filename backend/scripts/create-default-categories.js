const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function createDefaultCategories() {
  try {
    // Find the test shop
    const shop = await prisma.shop.findFirst({
      where: {
        name: 'Test Restaurant'
      }
    });

    if (!shop) {
      console.log('Test shop not found');
      return;
    }

    console.log('Found shop:', shop.name, 'ID:', shop.id);

    // Create default categories
    const categories = [
      {
        id: 'cat-12345678-1234-1234-1234-123456789012',
        name: 'Main Course',
        description: 'Hearty main dishes and entrees',
        shopId: shop.id,
        status: 'ACTIVE'
      },
      {
        id: 'cat-87654321-4321-4321-4321-210987654321',
        name: 'Salads',
        description: 'Fresh and healthy salads',
        shopId: shop.id,
        status: 'ACTIVE'
      },
      {
        id: 'cat-11111111-1111-1111-1111-111111111111',
        name: 'Beverages',
        description: 'Drinks and beverages',
        shopId: shop.id,
        status: 'ACTIVE'
      },
      {
        id: 'cat-22222222-2222-2222-2222-222222222222',
        name: 'Desserts',
        description: 'Sweet treats and desserts',
        shopId: shop.id,
        status: 'ACTIVE'
      }
    ];

    for (const category of categories) {
      try {
        const existing = await prisma.category.findUnique({
          where: { id: category.id }
        });

        if (!existing) {
          await prisma.category.create({
            data: category
          });
          console.log('Created category:', category.name);
        } else {
          console.log('Category already exists:', category.name);
        }
      } catch (error) {
        console.log('Error creating category', category.name, ':', error.message);
      }
    }

    console.log('Done creating categories');
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createDefaultCategories(); 
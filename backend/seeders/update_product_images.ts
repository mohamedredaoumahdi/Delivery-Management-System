import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Helper function to get image URL
const getImageUrl = (path: string | null): string | null => {
  if (!path) return null;
  return `/uploads/${path}`;
};

async function main() {
  console.log('Updating product images...');

  // Product image mappings
  const productImageMap: Record<string, string | null> = {
    // Pizza Palace products
    'Margherita Pizza': getImageUrl('products/product-margherita-pizza.jpg'),
    'Pepperoni Pizza': getImageUrl('products/product-pepperoni-pizza.jpg'),
    'Veggie Pizza': getImageUrl('products/product-veggie-pizza.jpg'),
    'Hawaiian Pizza': getImageUrl('products/product-hawaiian-pizza.jpg'),
    'Meat Lovers Pizza': getImageUrl('products/product-meat-lovers-pizza.jpg'),
    'Cheese Pizza': getImageUrl('products/product-cheese-pizza.jpg'),
    'Supreme Pizza': getImageUrl('products/product-supreme-pizza.jpg'),
    'BBQ Chicken Pizza': getImageUrl('products/product-bbq-chicken-pizza.jpg'),
    'Coca Cola': getImageUrl('products/product-coca-cola.jpeg'),
    'Pepsi': getImageUrl('products/product-pepsi.jpg'),
    
    // Fresh Market products
    'Fresh Bananas': getImageUrl('products/product-fresh-bananas.jpg'),
    'Red Apples': getImageUrl('products/product-apples.jpg'),
    'Fresh Bread': getImageUrl('products/product-bread.jpg'),
    'Whole Milk': getImageUrl('products/product-milk.jpg'),
    'Fresh Eggs': getImageUrl('products/product-eggs.jpg'),
    'Tomatoes': getImageUrl('products/product-tomatoes.jpg'),
    'Chicken Breast': getImageUrl('products/product-chicken-breast.jpg'),
    'Rice': getImageUrl('products/product-rice.jpg'),
    
    // Burger King products
    'Classic Burger': getImageUrl('products/product-classic-burger.jpg'),
    'Cheese Burger': getImageUrl('products/product-cheese-burger.jpg'),
    'Bacon Burger': getImageUrl('products/product-bacon-burger.jpg'),
    'Double Burger': getImageUrl('products/product-double-burger.jpg'),
    'Veggie Burger': getImageUrl('products/product-veggie-burger.jpg'),
    'French Fries': getImageUrl('products/product-fries.jpg'),
    
    // Sushi House products
    'Salmon Roll': getImageUrl('products/product-salmon-roll.jpg'),
    'Tuna Roll': getImageUrl('products/product-tuna-roll.jpg'),
    'California Roll': getImageUrl('products/product-california-roll.jpg'),
    'Dragon Roll': getImageUrl('products/product-dragon-roll.jpg'),
    'Sashimi Platter': getImageUrl('products/product-sashimi-platter.jpeg'),
    
    // Coffee Corner products
    'Espresso': getImageUrl('products/product-espresso.jpg'),
    'Americano': getImageUrl('products/product-americano.jpg'),
    'Cappuccino': getImageUrl('products/product-cappuccino.jpg'),
    'Latte': getImageUrl('products/product-latte.jpg'),
    'Mocha': getImageUrl('products/product-mocha.jpg'),
    'Croissant': getImageUrl('products/product-croissant.jpg'),
    
    // Bakery Bliss products
    'Fresh Baguette': getImageUrl('products/product-baguette.png'),
    'Chocolate Donut': getImageUrl('products/product-donut.jpg'),
    'Cake Slice': getImageUrl('products/product-cake-slice.jpg'),
    'Chocolate Cookies': getImageUrl('products/product-cookies.jpg'),
    
    // Chicken Grill products
    'Fried Chicken': '/uploads/products/product-fried-chicken.jpg.png',
    'Chicken Wings': getImageUrl('products/product-chicken-wings.jpg'),
    'Coleslaw': getImageUrl('products/product-coleslaw.jpg'),
    
    // Ice Cream Parlor products
    'Ice Cream Sundae': getImageUrl('products/product-ice-cream-sundae.jpeg'),
    'Chocolate Ice Cream': getImageUrl('products/product-chocolate-ice-cream.jpg'),
    'Strawberry Ice Cream': getImageUrl('products/product-strawberry-ice-cream.jpg'),
    
    // Fast Food Express products
    'Garden Salad': getImageUrl('products/product-salad.jpg'),
    'Chicken Soup': getImageUrl('products/product-soup.jpg'),
    
    // Mega Retail Store products (initial batch)
    'Wireless Headphones': getImageUrl('products/product-wireless-headphones.jpg'),
    'Smartphone Case': getImageUrl('products/product-smartphone-case.jpg'),
    'USB-C Charging Cable': getImageUrl('products/product-usb-cable.jpg'),
    'Bluetooth Speaker': getImageUrl('products/product-bluetooth-speaker.jpg'),
    'Classic T-Shirt': getImageUrl('products/product-t-shirt.jpg'),
    'Denim Jeans': getImageUrl('products/product-denim-jeans.jpg'),
    'Running Shoes': getImageUrl('products/product-running-shoes.jpg'),
    'Winter Jacket': getImageUrl('products/product-winter-jacket.jpg'),
    'Throw Pillow Set': getImageUrl('products/product-throw-pillow-set.jpg'),
    'Garden Tool Set': getImageUrl('products/product-garden-tool-set.jpg'),
  };

  let updatedCount = 0;

  // Update each product individually
  for (const [productName, imageUrl] of Object.entries(productImageMap)) {
    if (imageUrl) {
      const result = await prisma.product.updateMany({
        where: { name: productName },
        data: {
          imageUrl: imageUrl,
          images: [imageUrl],
        },
      });
      
      if (result.count > 0) {
        updatedCount += result.count;
        console.log(`  ✅ Updated "${productName}" with image`);
      }
    }
  }

  console.log(`\n✅ Product images updated successfully!`);
  console.log(`   Updated ${updatedCount} products with images`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

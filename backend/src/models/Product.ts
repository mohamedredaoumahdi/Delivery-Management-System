import { Product as PrismaProduct, Prisma } from '@prisma/client';
import { prisma } from '@/config/database'; // Assuming your prisma client is exported from here

export type Product = PrismaProduct;

// Example: Function to find products by shop ID
export const findProductsByShopId = async (shopId: string): Promise<Product[]> => {
  return prisma.product.findMany({
    where: { shopId },
  });
};

// Add other product-related database interaction functions here

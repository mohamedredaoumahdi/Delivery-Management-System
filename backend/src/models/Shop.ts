import { Shop as PrismaShop, Prisma } from '@prisma/client';
import { prisma } from '@/config/database'; // Assuming your prisma client is exported from here

export type Shop = PrismaShop;

// Example: Function to find a shop by ID
export const findShopById = async (id: string): Promise<Shop | null> => {
  return prisma.shop.findUnique({
    where: { id },
    include: { // Include related data as needed
      products: true,
      owner: true,
    },
  });
};

// Example: Function to get all shops
// export const getAllShops = async (): Promise<Shop[]> => {
//   return prisma.shop.findMany();
// };

// Add other shop-related database interaction functions here

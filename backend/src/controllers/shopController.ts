import { Request, Response } from 'express';
import { Shop } from '@/models/Shop';
import { Product } from '@/models/Product';
import { Category } from '@/models/Category';
import { AppError } from '@/utils/AppError';

export class ShopController {
  async getShops(req: Request, res: Response) {
    const shops = await Shop.find({ status: 'ACTIVE' })
      .select('-__v')
      .sort({ rating: -1 });
    res.json(shops);
  }

  async getFeaturedShops(req: Request, res: Response) {
    const shops = await Shop.find({ 
      status: 'ACTIVE',
      isFeatured: true 
    })
      .select('-__v')
      .sort({ rating: -1 })
      .limit(10);
    res.json(shops);
  }

  async getNearbyShops(req: Request, res: Response) {
    const { lat, lng, radius = 5 } = req.query;
    
    if (!lat || !lng) {
      throw new AppError('Location coordinates are required', 400);
    }

    const shops = await Shop.find({
      status: 'ACTIVE',
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng as string), parseFloat(lat as string)]
          },
          $maxDistance: parseFloat(radius as string) * 1000 // Convert km to meters
        }
      }
    })
      .select('-__v')
      .limit(20);

    res.json(shops);
  }

  async getShopById(req: Request, res: Response) {
    const shop = await Shop.findById(req.params.id)
      .select('-__v');
    
    if (!shop) {
      throw new AppError('Shop not found', 404);
    }

    res.json(shop);
  }

  async getShopProducts(req: Request, res: Response) {
    const products = await Product.find({ 
      shop: req.params.id,
      status: 'ACTIVE'
    })
      .select('-__v')
      .sort({ createdAt: -1 });

    res.json(products);
  }

  async getShopCategories(req: Request, res: Response) {
    const categories = await Category.find({ 
      shop: req.params.id,
      status: 'ACTIVE'
    })
      .select('-__v')
      .sort({ name: 1 });

    res.json(categories);
  }
} 
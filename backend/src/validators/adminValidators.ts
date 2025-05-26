import Joi from 'joi';

export const updateUserSchema = Joi.object({
  name: Joi.string().min(2).max(50),
  email: Joi.string().email(),
  role: Joi.string().valid('USER', 'VENDOR', 'DELIVERY', 'ADMIN'),
  isActive: Joi.boolean(),
});

export const createShopSchema = Joi.object({
  name: Joi.string().required().min(2).max(100),
  description: Joi.string().required().min(10).max(500),
  address: Joi.string().required().min(5).max(200),
  latitude: Joi.number().required().min(-90).max(90),
  longitude: Joi.number().required().min(-180).max(180),
  phone: Joi.string().required().pattern(/^\+?[\d\s-]{10,}$/),
  email: Joi.string().required().email(),
  openingHours: Joi.string().required(),
  category: Joi.string().valid('RESTAURANT', 'GROCERY', 'PHARMACY', 'RETAIL', 'OTHER').required(),
  estimatedDeliveryTime: Joi.number().required().min(0),
  ownerId: Joi.string().required(),
  website: Joi.string().uri().allow(''),
  hasDelivery: Joi.boolean(),
  hasPickup: Joi.boolean(),
  minimumOrderAmount: Joi.number().min(0),
  deliveryFee: Joi.number().min(0),
});

export const updateShopSchema = Joi.object({
  name: Joi.string().min(2).max(100),
  description: Joi.string().min(10).max(500),
  address: Joi.string().min(5).max(200),
  latitude: Joi.number().min(-90).max(90),
  longitude: Joi.number().min(-180).max(180),
  phone: Joi.string().pattern(/^\+?[\d\s-]{10,}$/),
  email: Joi.string().email(),
  openingHours: Joi.string(),
  categoryId: Joi.string(),
  isActive: Joi.boolean(),
});

export const createCategorySchema = Joi.object({
  name: Joi.string().required().min(2).max(50),
  description: Joi.string().required().min(10).max(200),
  // image is handled by multer middleware
});

export const updateCategorySchema = Joi.object({
  name: Joi.string().min(2).max(50),
  description: Joi.string().min(10).max(200),
  // image is handled by multer middleware
  isActive: Joi.boolean(),
}); 
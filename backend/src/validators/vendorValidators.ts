import Joi from 'joi';

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

export const createProductSchema = Joi.object({
  name: Joi.string().required().min(2).max(100),
  description: Joi.string().required().min(10).max(500),
  price: Joi.number().required().min(0),
  categoryId: Joi.string().required(),
  isAvailable: Joi.boolean(),
  preparationTime: Joi.number().min(0),
}); 
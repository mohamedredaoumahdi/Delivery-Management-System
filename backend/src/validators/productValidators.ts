import Joi from 'joi';

export const createProductSchema = Joi.object({
  name: Joi.string().required().min(3).max(100),
  description: Joi.string().required().min(10).max(1000),
  price: Joi.number().required().min(0),
  categoryId: Joi.string().required(),
});

export const updateProductSchema = Joi.object({
  name: Joi.string().min(3).max(100),
  description: Joi.string().min(10).max(1000),
  price: Joi.number().min(0),
  categoryId: Joi.string(),
  inStock: Joi.boolean(),
  stockQuantity: Joi.number().min(0)
}); 
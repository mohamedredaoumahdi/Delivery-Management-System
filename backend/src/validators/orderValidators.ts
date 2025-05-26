import Joi from 'joi';
import { PaymentMethod } from '@prisma/client';

export const createOrderSchema = Joi.object({
  shopId: Joi.string().required(),
  items: Joi.array().items(
    Joi.object({
      productId: Joi.string().required(),
      quantity: Joi.number().integer().min(1).required(),
      instructions: Joi.string().optional(),
    })
  ).required(),
  deliveryAddress: Joi.string().required(),
  paymentMethod: Joi.string().valid(...Object.values(PaymentMethod)).required(),
});

export const updateOrderSchema = Joi.object({
  tip: Joi.number().min(0).required(),
}); 
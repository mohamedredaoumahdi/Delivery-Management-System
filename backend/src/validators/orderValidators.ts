import Joi from 'joi';
import { PaymentMethod } from '@prisma/client';

export const createOrderSchema = Joi.object({
  shopId: Joi.string().required(),
  items: Joi.array().items(
    Joi.object({
      productId: Joi.string().required(),
      productName: Joi.string().required(),
      productPrice: Joi.number().positive().required(),
      quantity: Joi.number().integer().min(1).required(),
      totalPrice: Joi.number().positive().required(),
      instructions: Joi.string().optional().allow('', null),
    })
  ).required(),
  deliveryAddress: Joi.string().required(),
  deliveryLatitude: Joi.number().optional(),
  deliveryLongitude: Joi.number().optional(),
  deliveryInstructions: Joi.string().optional().allow('', null),
  paymentMethod: Joi.string().valid(...Object.values(PaymentMethod)).required(),
  tip: Joi.number().min(0).optional().default(0),
});

export const updateOrderSchema = Joi.object({
  tip: Joi.number().min(0).required(),
});

export const cancelOrderSchema = Joi.object({
  reason: Joi.string().optional(),
});

export const updateOrderStatusSchema = Joi.object({
  status: Joi.string().required(),
  rejectionReason: Joi.string().optional(),
  estimatedDeliveryTime: Joi.date().optional(),
}); 
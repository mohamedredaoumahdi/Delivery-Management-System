import Joi from 'joi';

export const createAddressSchema = Joi.object({
  label: Joi.string().required().min(2).max(50),
  fullAddress: Joi.string().required().min(5).max(200),
  latitude: Joi.number().required().min(-90).max(90),
  longitude: Joi.number().required().min(-180).max(180),
  instructions: Joi.string().max(200),
  isDefault: Joi.boolean(),
});

export const updateAddressSchema = Joi.object({
  label: Joi.string().min(2).max(50),
  fullAddress: Joi.string().min(5).max(200),
  latitude: Joi.number().min(-90).max(90),
  longitude: Joi.number().min(-180).max(180),
  instructions: Joi.string().max(200),
  isDefault: Joi.boolean(),
}); 
import Joi from 'joi';

export const updateProfileSchema = Joi.object({
  name: Joi.string().min(2).max(50),
  phone: Joi.string().pattern(/^\+?[\d\s-]{10,}$/),
});

export const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required().min(6),
  newPassword: Joi.string().required().min(6),
}); 
import Joi from 'joi';

export const createReviewSchema = Joi.object({
  rating: Joi.number().required().min(1).max(5),
  comment: Joi.string().required().min(10).max(500),
  shopId: Joi.string().required(),
  productId: Joi.string(),
});

export const updateReviewSchema = Joi.object({
  rating: Joi.number().min(1).max(5),
  comment: Joi.string().min(10).max(500),
}); 
import Joi from 'joi';
import { PaymentMethodType } from '@prisma/client';

export const createPaymentMethodSchema = Joi.object({
  type: Joi.string().valid(...Object.values(PaymentMethodType)).required(),
  label: Joi.string().min(1).max(50).required(),
  
  // Card details (required for CREDIT_CARD, DEBIT_CARD)
  cardLast4: Joi.when('type', {
    is: Joi.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
    then: Joi.string().length(4).pattern(/^\d{4}$/).required(),
    otherwise: Joi.string().optional()
  }),
  cardBrand: Joi.when('type', {
    is: Joi.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
    then: Joi.string().valid('visa', 'mastercard', 'amex', 'discover', 'other').required(),
    otherwise: Joi.string().optional()
  }),
  cardExpiryMonth: Joi.when('type', {
    is: Joi.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
    then: Joi.number().integer().min(1).max(12).required(),
    otherwise: Joi.number().optional()
  }),
  cardExpiryYear: Joi.when('type', {
    is: Joi.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
    then: Joi.number().integer().min(new Date().getFullYear()).max(new Date().getFullYear() + 20).required(),
    otherwise: Joi.number().optional()
  }),
  cardHolderName: Joi.when('type', {
    is: Joi.string().valid('CREDIT_CARD', 'DEBIT_CARD'),
    then: Joi.string().min(2).max(100).required(),
    otherwise: Joi.string().optional()
  }),
  
  // Digital wallet details
  walletEmail: Joi.when('type', {
    is: Joi.string().valid('PAYPAL'),
    then: Joi.string().email().required(),
    otherwise: Joi.string().email().optional()
  }),
  walletProvider: Joi.when('type', {
    is: Joi.string().valid('PAYPAL', 'APPLE_PAY', 'GOOGLE_PAY'),
    then: Joi.string().valid('paypal', 'apple_pay', 'google_pay').required(),
    otherwise: Joi.string().optional()
  }),
  
  // Bank account details
  bankName: Joi.when('type', {
    is: Joi.string().valid('BANK_ACCOUNT'),
    then: Joi.string().min(2).max(100).required(),
    otherwise: Joi.string().optional()
  }),
  bankAccountLast4: Joi.when('type', {
    is: Joi.string().valid('BANK_ACCOUNT'),
    then: Joi.string().length(4).pattern(/^\d{4}$/).required(),
    otherwise: Joi.string().optional()
  }),
  
  // Common fields
  isDefault: Joi.boolean().optional()
});

export const updatePaymentMethodSchema = Joi.object({
  label: Joi.string().min(1).max(50).optional(),
  
  // Card details (updatable)
  cardExpiryMonth: Joi.number().integer().min(1).max(12).optional(),
  cardExpiryYear: Joi.number().integer().min(new Date().getFullYear()).max(new Date().getFullYear() + 20).optional(),
  cardHolderName: Joi.string().min(2).max(100).optional(),
  
  // Digital wallet details
  walletEmail: Joi.string().email().optional(),
  
  // Bank account details
  bankName: Joi.string().min(2).max(100).optional(),
  
  // Common fields
  isDefault: Joi.boolean().optional()
});

export const paymentMethodIdSchema = Joi.object({
  paymentMethodId: Joi.string().uuid().required()
}); 
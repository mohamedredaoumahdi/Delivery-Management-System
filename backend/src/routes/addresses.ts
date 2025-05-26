import { Router } from 'express';
import { AddressController } from '@/controllers/addressController';
import { auth } from '@/middleware/auth';
import { validateRequest } from '@/middleware/validation';
import { createAddressSchema, updateAddressSchema } from '@/validators/addressValidators';

const router = Router();
const addressController = new AddressController();

// All address routes require authentication
router.use(auth);

// Address management
router.get('/', addressController.getAddresses);
router.post('/', validateRequest(createAddressSchema), addressController.createAddress);
router.put('/:id', validateRequest(updateAddressSchema), addressController.updateAddress);
router.delete('/:id', addressController.deleteAddress);
router.put('/:id/set-default', addressController.setDefaultAddress);

export default router; 
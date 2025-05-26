"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const addressController_1 = require("@/controllers/addressController");
const auth_1 = require("@/middleware/auth");
const validation_1 = require("@/middleware/validation");
const addressValidators_1 = require("@/validators/addressValidators");
const router = (0, express_1.Router)();
const addressController = new addressController_1.AddressController();
router.use(auth_1.auth);
router.get('/', addressController.getAddresses);
router.post('/', (0, validation_1.validateRequest)(addressValidators_1.createAddressSchema), addressController.createAddress);
router.put('/:id', (0, validation_1.validateRequest)(addressValidators_1.updateAddressSchema), addressController.updateAddress);
router.delete('/:id', addressController.deleteAddress);
router.put('/:id/set-default', addressController.setDefaultAddress);
exports.default = router;
//# sourceMappingURL=addresses.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const orderController_1 = require("@/controllers/orderController");
const auth_1 = require("@/middleware/auth");
const validation_1 = require("@/middleware/validation");
const orderValidators_1 = require("@/validators/orderValidators");
const router = (0, express_1.Router)();
const orderController = new orderController_1.OrderController();
router.use(auth_1.auth);
router.post('/', (0, validation_1.validateRequest)(orderValidators_1.createOrderSchema), orderController.createOrder);
router.get('/', orderController.getUserOrders);
router.get('/:id', orderController.getOrderById);
router.patch('/:id/cancel', orderController.cancelOrder);
router.patch('/:id/tip', (0, validation_1.validateRequest)(orderValidators_1.updateOrderSchema), orderController.updateTip);
router.get('/:id/track', orderController.trackOrder);
exports.default = router;
//# sourceMappingURL=orders.js.map
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const paymentMethodController_1 = require("../controllers/paymentMethodController");
const auth_1 = require("../middleware/auth");
const validation_1 = require("../middleware/validation");
const catchAsync_1 = require("../utils/catchAsync");
const paymentMethodValidators_1 = require("../validators/paymentMethodValidators");
const router = express_1.default.Router();
const paymentMethodController = new paymentMethodController_1.PaymentMethodController();
router.use(auth_1.auth);
router.get('/', (0, catchAsync_1.catchAsync)(paymentMethodController.getPaymentMethods));
router.post('/', (0, validation_1.validateRequest)(paymentMethodValidators_1.createPaymentMethodSchema), (0, catchAsync_1.catchAsync)(paymentMethodController.createPaymentMethod));
router.put('/:paymentMethodId', (0, validation_1.validateRequest)(paymentMethodValidators_1.updatePaymentMethodSchema), (0, catchAsync_1.catchAsync)(paymentMethodController.updatePaymentMethod));
router.delete('/:paymentMethodId', (0, catchAsync_1.catchAsync)(paymentMethodController.deletePaymentMethod));
router.put('/:paymentMethodId/default', (0, catchAsync_1.catchAsync)(paymentMethodController.setDefaultPaymentMethod));
exports.default = router;
//# sourceMappingURL=paymentMethods.js.map
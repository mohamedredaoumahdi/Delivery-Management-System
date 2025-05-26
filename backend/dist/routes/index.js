"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = __importDefault(require("./auth"));
const shops_1 = __importDefault(require("./shops"));
const orders_1 = __importDefault(require("./orders"));
const vendor_1 = __importDefault(require("./vendor"));
const delivery_1 = __importDefault(require("./delivery"));
const admin_1 = __importDefault(require("./admin"));
const users_1 = __importDefault(require("./users"));
const products_1 = __importDefault(require("./products"));
const addresses_1 = __importDefault(require("./addresses"));
const reviews_1 = __importDefault(require("./reviews"));
const router = (0, express_1.Router)();
router.use('/auth', auth_1.default);
router.use('/shops', shops_1.default);
router.use('/orders', orders_1.default);
router.use('/vendor', vendor_1.default);
router.use('/delivery', delivery_1.default);
router.use('/admin', admin_1.default);
router.use('/users', users_1.default);
router.use('/products', products_1.default);
router.use('/addresses', addresses_1.default);
router.use('/reviews', reviews_1.default);
exports.default = router;
//# sourceMappingURL=index.js.map
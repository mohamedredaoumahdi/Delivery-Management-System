"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authController_1 = require("@/controllers/authController");
const validation_1 = require("@/middleware/validation");
const authValidators_1 = require("@/validators/authValidators");
const rateLimiter_1 = require("@/middleware/rateLimiter");
const router = (0, express_1.Router)();
const authController = new authController_1.AuthController();
router.use(rateLimiter_1.rateLimiter);
router.post('/register', (0, validation_1.validateRequest)(authValidators_1.registerSchema), authController.register);
router.post('/login', (0, validation_1.validateRequest)(authValidators_1.loginSchema), authController.login);
router.post('/refresh', authController.refreshToken);
router.post('/logout', authController.logout);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.post('/verify-email', authController.verifyEmail);
exports.default = router;
//# sourceMappingURL=auth.js.map
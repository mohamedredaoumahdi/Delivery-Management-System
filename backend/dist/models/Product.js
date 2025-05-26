"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findProductsByShopId = void 0;
const database_1 = require("@/config/database");
const findProductsByShopId = async (shopId) => {
    return database_1.prisma.product.findMany({
        where: { shopId },
    });
};
exports.findProductsByShopId = findProductsByShopId;
//# sourceMappingURL=Product.js.map
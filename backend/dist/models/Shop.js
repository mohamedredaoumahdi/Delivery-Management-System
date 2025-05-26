"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findShopById = void 0;
const database_1 = require("@/config/database");
const findShopById = async (id) => {
    return database_1.prisma.shop.findUnique({
        where: { id },
        include: {
            products: true,
            owner: true,
        },
    });
};
exports.findShopById = findShopById;
//# sourceMappingURL=Shop.js.map
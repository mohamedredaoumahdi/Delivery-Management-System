"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findOrderById = void 0;
const database_1 = require("@/config/database");
const findOrderById = async (id) => {
    return database_1.prisma.order.findUnique({
        where: { id },
        include: {
            items: true,
            user: true,
            shop: true,
        },
    });
};
exports.findOrderById = findOrderById;
//# sourceMappingURL=Order.js.map
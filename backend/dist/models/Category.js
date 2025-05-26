"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Category = void 0;
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
class Category {
    static async findMany(where, select, orderBy) {
        return prisma.category.findMany({
            where,
            select,
            orderBy,
        });
    }
    static async findUnique(where, select) {
        return prisma.category.findUnique({
            where,
            select,
        });
    }
    static async create(data) {
        return prisma.category.create({
            data,
        });
    }
    static async update(where, data) {
        return prisma.category.update({
            where,
            data,
        });
    }
    static async delete(where) {
        return prisma.category.delete({
            where,
        });
    }
}
exports.Category = Category;
//# sourceMappingURL=Category.js.map
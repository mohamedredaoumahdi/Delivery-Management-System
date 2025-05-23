"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cache = void 0;
const cache = (duration) => {
    return (req, res, next) => {
        if (req.method !== 'GET') {
            return next();
        }
        res.set('Cache-Control', `public, max-age=${duration}`);
        next();
    };
};
exports.cache = cache;
//# sourceMappingURL=cache.js.map
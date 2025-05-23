"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.resizeImages = exports.upload = void 0;
const multer_1 = __importDefault(require("multer"));
const sharp_1 = __importDefault(require("sharp"));
const config_1 = require("@/config/config");
const appError_1 = require("@/utils/appError");
const multerStorage = multer_1.default.memoryStorage();
const multerFilter = (req, file, cb) => {
    if (file.mimetype.startsWith('image')) {
        cb(null, true);
    }
    else {
        cb(new appError_1.AppError('Not an image! Please upload only images.', 400));
    }
};
exports.upload = (0, multer_1.default)({
    storage: multerStorage,
    fileFilter: multerFilter,
    limits: {
        fileSize: config_1.config.maxFileSize,
    },
});
const resizeImages = (req, res, next) => {
    if (!req.files)
        return next();
    req.body.images = [];
    Promise.all(req.files.map(async (file, i) => {
        const filename = `image-${Date.now()}-${i + 1}.jpeg`;
        await (0, sharp_1.default)(file.buffer)
            .resize(800, 600)
            .toFormat('jpeg')
            .jpeg({ quality: 90 })
            .toFile(`${config_1.config.uploadDir}/${filename}`);
        req.body.images.push(filename);
    }))
        .then(() => next())
        .catch(next);
};
exports.resizeImages = resizeImages;
//# sourceMappingURL=upload.js.map
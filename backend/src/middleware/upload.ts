import multer from 'multer';
import sharp from 'sharp';
import path from 'path';
import { Request } from 'express';
import { config } from '@/config/config';
import { AppError } from '@/utils/appError';

// Multer configuration
const multerStorage = multer.memoryStorage();

const multerFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  if (file.mimetype.startsWith('image')) {
    cb(null, true);
  } else {
    cb(new AppError('Not an image! Please upload only images.', 400));
  }
};

export const upload = multer({
  storage: multerStorage,
  fileFilter: multerFilter,
  limits: {
    fileSize: config.maxFileSize, // 10MB
  },
});

// Image resizing middleware
export const resizeImages = (req: Request, res: any, next: NextFunction) => {
  if (!req.files) return next();

  req.body.images = [];

  Promise.all(
    (req.files as Express.Multer.File[]).map(async (file, i) => {
      const filename = `image-${Date.now()}-${i + 1}.jpeg`;

      await sharp(file.buffer)
        .resize(800, 600)
        .toFormat('jpeg')
        .jpeg({ quality: 90 })
        .toFile(`${config.uploadDir}/${filename}`);

      req.body.images.push(filename);
    })
  )
    .then(() => next())
    .catch(next);
}; 
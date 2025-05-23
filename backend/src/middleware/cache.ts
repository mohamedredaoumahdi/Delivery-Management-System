import { Request, Response, NextFunction } from 'express';

export const cache = (duration: number) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    // Only cache GET requests
    if (req.method !== 'GET') {
      return next();
    }

    res.set('Cache-Control', `public, max-age=${duration}`);
    next();
  };
}; 
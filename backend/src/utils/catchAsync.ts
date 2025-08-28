import { Request, Response, NextFunction } from 'express';

type AsyncHandler = (req: Request, res: Response, next: NextFunction) => Promise<any> | any;

export const catchAsync = (fn: AsyncHandler) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const result = fn(req, res, next);
    if (result && typeof result.then === 'function') {
      result.catch(next);
    }
  };
};
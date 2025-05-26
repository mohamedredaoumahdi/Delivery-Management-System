import { Request } from 'express';

export interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    // Add other user properties as needed
  };
}

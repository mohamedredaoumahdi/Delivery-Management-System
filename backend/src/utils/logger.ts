import { config } from '@/config/config';

interface Logger {
  info: (message: string, ...args: any[]) => void;
  error: (message: string, error?: any) => void;
  warn: (message: string, ...args: any[]) => void;
  debug: (message: string, ...args: any[]) => void;
}

const createLogger = (): Logger => {
  const isDevelopment = config.nodeEnv === 'development';

  return {
    info: (message: string, ...args: any[]) => {
      if (isDevelopment) {
        console.log(`[INFO] ${new Date().toISOString()} - ${message}`, ...args);
      } else {
        console.log(JSON.stringify({
          level: 'info',
          timestamp: new Date().toISOString(),
          message,
          data: args,
        }));
      }
    },

    error: (message: string, error?: any) => {
      if (isDevelopment) {
        console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, error);
      } else {
        console.error(JSON.stringify({
          level: 'error',
          timestamp: new Date().toISOString(),
          message,
          error: error?.stack || error,
        }));
      }
    },

    warn: (message: string, ...args: any[]) => {
      if (isDevelopment) {
        console.warn(`[WARN] ${new Date().toISOString()} - ${message}`, ...args);
      } else {
        console.warn(JSON.stringify({
          level: 'warn',
          timestamp: new Date().toISOString(),
          message,
          data: args,
        }));
      }
    },

    debug: (message: string, ...args: any[]) => {
      if (isDevelopment) {
        console.debug(`[DEBUG] ${new Date().toISOString()} - ${message}`, ...args);
      }
    },
  };
};

export const logger = createLogger(); 
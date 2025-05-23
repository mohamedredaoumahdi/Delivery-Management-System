"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logger = void 0;
const config_1 = require("@/config/config");
const createLogger = () => {
    const isDevelopment = config_1.config.nodeEnv === 'development';
    return {
        info: (message, ...args) => {
            if (isDevelopment) {
                console.log(`[INFO] ${new Date().toISOString()} - ${message}`, ...args);
            }
            else {
                console.log(JSON.stringify({
                    level: 'info',
                    timestamp: new Date().toISOString(),
                    message,
                    data: args,
                }));
            }
        },
        error: (message, error) => {
            if (isDevelopment) {
                console.error(`[ERROR] ${new Date().toISOString()} - ${message}`, error);
            }
            else {
                console.error(JSON.stringify({
                    level: 'error',
                    timestamp: new Date().toISOString(),
                    message,
                    error: error?.stack || error,
                }));
            }
        },
        warn: (message, ...args) => {
            if (isDevelopment) {
                console.warn(`[WARN] ${new Date().toISOString()} - ${message}`, ...args);
            }
            else {
                console.warn(JSON.stringify({
                    level: 'warn',
                    timestamp: new Date().toISOString(),
                    message,
                    data: args,
                }));
            }
        },
        debug: (message, ...args) => {
            if (isDevelopment) {
                console.debug(`[DEBUG] ${new Date().toISOString()} - ${message}`, ...args);
            }
        },
    };
};
exports.logger = createLogger();
//# sourceMappingURL=logger.js.map
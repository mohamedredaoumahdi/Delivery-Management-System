import fs from 'fs';
import path from 'path';

export interface WhitelabelConfig {
  app: {
    name: string;
    shortName: string;
    description: string;
    version: string;
    companyName?: string;
    supportEmail?: string;
    website?: string;
    helpCenterUrl?: string;
    supportUrl?: string;
    termsOfServiceUrl?: string;
    privacyPolicyUrl?: string;
    appStoreUrl?: string;
    playStoreUrl?: string;
  };
  branding: {
    primaryColor: string;
    secondaryColor: string;
    accentColor: string;
    errorColor?: string;
    successColor?: string;
    warningColor?: string;
    logoPath?: string;
    faviconPath?: string;
  };
  apps: {
    user: { name: string; packageName: string };
    vendor: { name: string; packageName: string };
    delivery: { name: string; packageName: string };
    admin: { name: string; packageName: string };
  };
  features: {
    enablePushNotifications: boolean;
    enableSMS: boolean;
    enableEmailNotifications: boolean;
    enablePaymentGateway: boolean;
    enableReviews: boolean;
    enableFavorites: boolean;
    enableChat: boolean;
  };
  api: {
    baseUrl: string;
    timeout: number;
  };
  payment: {
    gateway: string;
    currency: string;
    deliveryFee: number;
    serviceFee: number;
  };
}

let config: WhitelabelConfig | null = null;

export function loadWhitelabelConfig(): WhitelabelConfig {
  if (config) {
    return config;
  }

  try {
    const configPath = path.join(process.cwd(), 'config', 'whitelabel.json');
    const configFile = fs.readFileSync(configPath, 'utf-8');
    config = JSON.parse(configFile) as WhitelabelConfig;
    return config;
  } catch (error) {
    // Return default config if file not found
    // Use logger instead of console for production safety
    if (process.env.NODE_ENV === 'development') {
      console.warn('Whitelabel config not found, using defaults');
    }
    return getDefaultConfig();
  }
}

function getDefaultConfig(): WhitelabelConfig {
  return {
    app: {
      name: 'Delivery System',
      shortName: 'Delivery',
      description: 'Complete delivery management system',
      version: '1.0.0',
      helpCenterUrl: process.env.HELP_CENTER_URL || 'https://help.yourdomain.com',
      supportUrl: process.env.SUPPORT_URL || 'mailto:support@yourdomain.com',
      termsOfServiceUrl: process.env.TERMS_URL || 'https://yourdomain.com/terms',
      privacyPolicyUrl: process.env.PRIVACY_URL || 'https://yourdomain.com/privacy',
      appStoreUrl: process.env.APP_STORE_URL || 'https://apps.apple.com/app/your-app',
      playStoreUrl: process.env.PLAY_STORE_URL || 'https://play.google.com/store/apps/details?id=your.app',
    },
    branding: {
      primaryColor: '#2196F3',
      secondaryColor: '#FF9800',
      accentColor: '#4CAF50',
    },
    apps: {
      user: { name: 'Customer App', packageName: 'com.example.delivery.customer' },
      vendor: { name: 'Vendor Dashboard', packageName: 'com.example.delivery.vendor' },
      delivery: { name: 'Delivery Driver', packageName: 'com.example.delivery.driver' },
      admin: { name: 'Admin Panel', packageName: 'com.example.delivery.admin' },
    },
    features: {
      enablePushNotifications: true,
      enableSMS: false,
      enableEmailNotifications: true,
      enablePaymentGateway: true,
      enableReviews: true,
      enableFavorites: true,
      enableChat: false,
    },
    api: {
      baseUrl: process.env.API_BASE_URL || 'http://localhost:3000/api',
      timeout: 30000,
    },
    payment: {
      gateway: 'stripe',
      currency: 'USD',
      deliveryFee: 2.99,
      serviceFee: 0.99,
    },
  };
}

export function getWhitelabelConfig(): WhitelabelConfig {
  return loadWhitelabelConfig();
}


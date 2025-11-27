# Configuration Guide

Complete guide for configuring the Delivery Management System.

## White-label Configuration

### Location

Main configuration file: `config/whitelabel.json`

### App Information

```json
{
  "app": {
    "name": "Your App Name",
    "shortName": "Short Name",
    "description": "App description",
    "version": "1.0.0",
    "companyName": "Your Company",
    "supportEmail": "support@example.com",
    "website": "https://example.com"
  }
}
```

### Branding

```json
{
  "branding": {
    "primaryColor": "#2196F3",
    "secondaryColor": "#FF9800",
    "accentColor": "#4CAF50",
    "errorColor": "#F44336",
    "successColor": "#4CAF50",
    "warningColor": "#FF9800",
    "logoPath": "assets/images/logo.png",
    "faviconPath": "assets/images/favicon.png"
  }
}
```

**Color Format:** Use hex colors (e.g., `#2196F3`)

**Logo Requirements:**
- Recommended size: 512x512px (PNG)
- Place in `assets/images/` directory
- Update `logoPath` accordingly

### App-Specific Configuration

```json
{
  "apps": {
    "user": {
      "name": "Customer App",
      "packageName": "com.yourcompany.delivery.customer"
    },
    "vendor": {
      "name": "Vendor Dashboard",
      "packageName": "com.yourcompany.delivery.vendor"
    },
    "delivery": {
      "name": "Delivery Driver",
      "packageName": "com.yourcompany.delivery.driver"
    },
    "admin": {
      "name": "Admin Panel",
      "packageName": "com.yourcompany.delivery.admin"
    }
  }
}
```

### Feature Flags

Enable/disable features:

```json
{
  "features": {
    "enablePushNotifications": true,
    "enableSMS": false,
    "enableEmailNotifications": true,
    "enablePaymentGateway": true,
    "enableReviews": true,
    "enableFavorites": true,
    "enableChat": false
  }
}
```

### API Configuration

```json
{
  "api": {
    "baseUrl": "http://localhost:3000/api",
    "timeout": 30000
  }
}
```

**Production:** Change to your production API URL

### Payment Configuration

```json
{
  "payment": {
    "gateway": "stripe",
    "currency": "USD",
    "deliveryFee": 2.99,
    "serviceFee": 0.99
  }
}
```

**Supported Gateways:**
- `stripe`
- `paypal`
- `razorpay`

## Backend Configuration

### Environment Variables

Edit `backend/.env`:

#### Database

```env
DATABASE_URL="postgresql://user:password@localhost:5432/delivery_db"
```

#### JWT Security

```env
JWT_SECRET=your-super-secret-key-min-32-characters
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
```

#### Server

```env
PORT=3000
NODE_ENV=development
CORS_ORIGIN=*
```

#### Email (Optional)

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

#### File Upload

```env
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=5242880
```

## Flutter App Configuration

### API Base URL

Update in each app's config file:

- `apps/user_app/lib/config/app_config.dart`
- `apps/vendor_app/lib/config/app_config.dart`
- `apps/delivery_app/lib/config/app_config.dart`
- `apps/admin_app/lib/config/app_config.dart`

```dart
static const String apiBaseUrl = 'http://your-api-url.com/api';
```

### Package Names

Update in `pubspec.yaml` for each app:

```yaml
name: your_app_name
```

And in platform-specific files:
- Android: `android/app/build.gradle`
- iOS: `ios/Runner.xcodeproj/project.pbxproj`

## Payment Gateway Setup

### Stripe

1. Get API keys from Stripe Dashboard
2. Add to backend `.env`:

```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

3. Update `config/whitelabel.json`:

```json
{
  "payment": {
    "gateway": "stripe"
  }
}
```

### PayPal

1. Get credentials from PayPal Developer
2. Add to backend `.env`:

```env
PAYPAL_CLIENT_ID=your-client-id
PAYPAL_CLIENT_SECRET=your-secret
PAYPAL_MODE=sandbox
```

## Push Notifications

### Firebase Setup

1. Create Firebase project
2. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Place in respective app directories
4. Enable in `config/whitelabel.json`:

```json
{
  "features": {
    "enablePushNotifications": true
  }
}
```

## Email Configuration

### SMTP Settings

Update backend `.env`:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM=noreply@yourdomain.com
```

**Gmail:** Use App Password (not regular password)

## Security Configuration

### Production Checklist

- [ ] Change `JWT_SECRET` to strong random string
- [ ] Set `NODE_ENV=production`
- [ ] Update `CORS_ORIGIN` to specific domains
- [ ] Use HTTPS for API
- [ ] Enable rate limiting
- [ ] Configure firewall rules
- [ ] Set up SSL certificates
- [ ] Enable database backups

## Customization Tips

### Changing Colors

1. Update colors in `config/whitelabel.json`
2. Restart apps to apply changes

### Adding Custom Logo

1. Place logo in `assets/images/logo.png`
2. Update `logoPath` in config
3. Rebuild apps

### Disabling Features

Set feature flags to `false` in `config/whitelabel.json`

## Troubleshooting

### Configuration Not Loading

- Check file path is correct
- Verify JSON syntax is valid
- Restart apps after changes

### Colors Not Applying

- Ensure hex format is correct (`#RRGGBB`)
- Restart app after changes
- Clear app cache if needed

## Advanced Configuration

See `SYSTEM_DOCUMENTATION.md` for detailed architecture and customization options.


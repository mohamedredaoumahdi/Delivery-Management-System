import 'dart:convert';
import 'package:flutter/services.dart';

class WhitelabelConfig {
  static WhitelabelConfig? _instance;
  Map<String, dynamic>? _config;

  WhitelabelConfig._();

  static WhitelabelConfig get instance {
    _instance ??= WhitelabelConfig._();
    return _instance!;
  }

  Future<void> loadConfig() async {
    try {
      final String jsonString = await rootBundle.loadString('config/whitelabel.json');
      _config = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Fallback to default config if file not found
      _config = _getDefaultConfig();
    }
  }

  void loadFromMap(Map<String, dynamic> config) {
    _config = config;
  }

  Map<String, dynamic> _getDefaultConfig() {
    return {
      'app': {
        'name': 'Delivery System',
        'shortName': 'Delivery',
        'description': 'Complete delivery management system',
        'version': '1.0.0',
        'helpCenterUrl': 'https://help.yourdomain.com',
        'supportUrl': 'mailto:support@yourdomain.com',
        'termsOfServiceUrl': 'https://yourdomain.com/terms',
        'privacyPolicyUrl': 'https://yourdomain.com/privacy',
        'appStoreUrl': 'https://apps.apple.com/app/your-app',
        'playStoreUrl': 'https://play.google.com/store/apps/details?id=your.app',
      },
      'branding': {
        'primaryColor': '#2196F3',
        'secondaryColor': '#FF9800',
        'accentColor': '#4CAF50',
      },
    };
  }

  // App Info
  String get appName => _config?['app']?['name'] ?? 'Delivery System';
  String get appShortName => _config?['app']?['shortName'] ?? 'Delivery';
  String get appDescription => _config?['app']?['description'] ?? '';
  String get appVersion => _config?['app']?['version'] ?? '1.0.0';
  String get companyName => _config?['app']?['companyName'] ?? '';
  String get supportEmail => _config?['app']?['supportEmail'] ?? '';
  String get website => _config?['app']?['website'] ?? '';
  
  // App URLs
  String get helpCenterUrl => _config?['app']?['helpCenterUrl'] ?? 'https://help.yourdomain.com';
  String get supportUrl => _config?['app']?['supportUrl'] ?? 'mailto:support@yourdomain.com';
  String get termsOfServiceUrl => _config?['app']?['termsOfServiceUrl'] ?? 'https://yourdomain.com/terms';
  String get privacyPolicyUrl => _config?['app']?['privacyPolicyUrl'] ?? 'https://yourdomain.com/privacy';
  String get appStoreUrl => _config?['app']?['appStoreUrl'] ?? 'https://apps.apple.com/app/your-app';
  String get playStoreUrl => _config?['app']?['playStoreUrl'] ?? 'https://play.google.com/store/apps/details?id=your.app';

  // Branding
  String get primaryColorHex => _config?['branding']?['primaryColor'] ?? '#2196F3';
  String get secondaryColorHex => _config?['branding']?['secondaryColor'] ?? '#FF9800';
  String get accentColorHex => _config?['branding']?['accentColor'] ?? '#4CAF50';
  String get logoPath => _config?['branding']?['logoPath'] ?? '';
  String get faviconPath => _config?['branding']?['faviconPath'] ?? '';

  // App-specific config
  Map<String, dynamic>? getAppConfig(String appType) {
    return _config?['apps']?[appType] as Map<String, dynamic>?;
  }

  String getAppName(String appType) {
    return getAppConfig(appType)?['name'] ?? appName;
  }

  String getPackageName(String appType) {
    return getAppConfig(appType)?['packageName'] ?? 'com.example.delivery.$appType';
  }

  // Features
  bool isFeatureEnabled(String feature) {
    return _config?['features']?[feature] ?? false;
  }

  // API
  String get apiBaseUrl => _config?['api']?['baseUrl'] ?? 'http://localhost:3000/api';
  int get apiTimeout => _config?['api']?['timeout'] ?? 30000;

  // Payment
  String get paymentGateway => _config?['payment']?['gateway'] ?? 'stripe';
  String get currency => _config?['payment']?['currency'] ?? 'USD';
  double get deliveryFee => (_config?['payment']?['deliveryFee'] ?? 2.99).toDouble();
  double get serviceFee => (_config?['payment']?['serviceFee'] ?? 0.99).toDouble();
}


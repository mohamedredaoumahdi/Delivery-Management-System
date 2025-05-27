import 'package:flutter/foundation.dart';

/// Environment configuration for the app
class Environment {
  static const String _dev = 'development';
  static const String _staging = 'staging';
  static const String _prod = 'production';

  static const String currentEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: _dev,
  );

  /// Base URL for API requests
  static String get baseUrl {
    switch (currentEnvironment) {
      case _dev:
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:3000/api'; // Android emulator
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          return 'http://localhost:3000/api'; // iOS simulator
        } else {
          return 'http://localhost:3000/api'; // Web/Desktop
        }
      case _staging:
        return 'https://staging-api.yourapp.com/api';
      case _prod:
        return 'https://api.yourapp.com/api';
      default:
        return 'http://10.0.2.2:3000/api';
    }
  }

  /// Whether the app is running in production mode
  static bool get isProduction => currentEnvironment == _prod;

  /// Whether the app is running in development mode
  static bool get isDevelopment => currentEnvironment == _dev;

  /// Whether the app is running in staging mode
  static bool get isStaging => currentEnvironment == _staging;

  /// Whether the app is running in debug mode
  static bool get isDebug => kDebugMode;

  /// Whether the app is running in profile mode
  static bool get isProfile => kProfileMode;
} 
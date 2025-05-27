import 'package:flutter/foundation.dart';

/// Environment configuration for the app
class Environment {
  /// Base URL for API requests
  static String get baseUrl {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:3000/api'; // Android emulator
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'http://localhost:3000/api'; // iOS simulator
      } else {
        return 'http://localhost:3000/api'; // Web/Desktop
      }
    } else {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.your-production-domain.com/api',
      );
    }
  }

  /// Whether the app is running in production mode
  static bool get isProduction => !kDebugMode;

  /// Whether the app is running in debug mode
  static bool get isDebug => kDebugMode;

  /// Whether the app is running in profile mode
  static bool get isProfile => kProfileMode;
} 
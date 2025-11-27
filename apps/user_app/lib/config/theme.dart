import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Theme configuration for User App
/// Uses the same design system as Vendor App and Delivery App for consistency
/// Primary color is blue to differentiate from other apps
class UserAppTheme {
  /// Create a custom blue theme for User App
  static DeliverySystemTheme _createBlueTheme() {
    return const DeliverySystemTheme(
      primaryColor: Color(0xFF2196F3), // Blue for user/customer
      secondaryColor: Color(0xFF64B5F6), // Lighter blue
      accentColor: Color(0xFFFF9800), // Orange for alerts/notifications
    );
  }
  
  /// Create the theme for the User App based on DeliverySystemTheme
  static ThemeData createTheme() {
    // Use blue theme for user app
    final baseTheme = _createBlueTheme();
    
    // Customize for User App (if needed)
    return baseTheme.themeData.copyWith(
      // Override specific theme properties if needed
      
      // Custom bottom navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        indicatorColor: baseTheme.primaryColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Custom app bar theme (matching other apps)
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: baseTheme.fontFamily,
        ),
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
      ),
      
      // Custom button shapes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      
      // Custom text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  /// Create a dark theme for the User App based on DeliverySystemTheme
  static ThemeData createDarkTheme() {
    // Use blue theme for user app dark mode
    final baseDarkTheme = _createBlueTheme().darkThemeData;
    
    // Customize for User App dark theme (if needed)
    return baseDarkTheme.copyWith(
      // Override specific theme properties if needed
      
      // Custom bottom navigation bar theme for dark mode
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        indicatorColor: Colors.blue.shade300.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Custom app bar theme for dark mode
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
    );
  }
}
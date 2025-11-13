import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Theme configuration for Vendor App
/// Uses the same design system as User App for consistency
/// Primary color is green to differentiate from user app
class VendorAppTheme {
  /// Create a custom green theme for Vendor App
  static DeliverySystemTheme _createGreenTheme() {
    return const DeliverySystemTheme(
      primaryColor: Color(0xFF2E7D32), // Green for business/vendor
      secondaryColor: Color(0xFF4CAF50), // Lighter green
      accentColor: Color(0xFFFF9800), // Orange for alerts/notifications
    );
  }
  
  /// Create the theme for the Vendor App based on DeliverySystemTheme
  static ThemeData createTheme() {
    // Use green theme for vendor app
    final baseTheme = _createGreenTheme();
    
    // Customize for Vendor App (if needed)
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
      
      // Custom app bar theme (matching user_app)
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
  
  /// Create a dark theme for the Vendor App based on DeliverySystemTheme
  static ThemeData createDarkTheme() {
    // Use green theme for vendor app dark mode
    final baseDarkTheme = _createGreenTheme().darkThemeData;
    
    // Customize for Vendor App dark theme (if needed)
    return baseDarkTheme.copyWith(
      // Override specific theme properties if needed
      
      // Custom bottom navigation bar theme for dark mode
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        indicatorColor: Colors.deepPurple.shade300.withValues(alpha: 0.3),
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
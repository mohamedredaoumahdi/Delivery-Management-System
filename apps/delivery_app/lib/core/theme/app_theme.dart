import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Theme configuration for Delivery App
/// Uses the same design system as User App and Vendor App for consistency
/// Primary color is yellow to differentiate from other apps
class DeliveryAppTheme {
  /// Create a custom yellow theme for Delivery App
  static DeliverySystemTheme _createYellowTheme() {
    return const DeliverySystemTheme(
      primaryColor: Color(0xFFF59E0B), // Yellow/Amber for delivery
      secondaryColor: Color(0xFFFBBF24), // Lighter yellow
      accentColor: Color(0xFFEF4444), // Red for urgent/important
    );
  }
  
  /// Create the theme for the Delivery App based on DeliverySystemTheme
  static ThemeData createTheme() {
    // Use yellow theme for delivery app
    final baseTheme = _createYellowTheme();
    
    // Customize for Delivery App (if needed)
    return baseTheme.themeData.copyWith(
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
          backgroundColor: baseTheme.primaryColor,
          foregroundColor: Colors.white,
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
  
  /// Create a dark theme for the Delivery App based on DeliverySystemTheme
  static ThemeData createDarkTheme() {
    // Use yellow theme for delivery app dark mode
    final baseDarkTheme = _createYellowTheme().darkThemeData;
    
    // Customize for Delivery App dark theme (if needed)
    return baseDarkTheme.copyWith(
      // Custom bottom navigation bar theme for dark mode
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        indicatorColor: Colors.amber.shade300.withValues(alpha: 0.3),
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

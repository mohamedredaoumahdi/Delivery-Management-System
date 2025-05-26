import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// Theme configuration for User App
class UserAppTheme {
  /// Create the theme for the User App based on DeliverySystemTheme
  static ThemeData createTheme() {
    // Use the default theme as a base
    final baseTheme = DeliverySystemTheme.defaultTheme();
    
    // Customize for User App (if needed)
    return baseTheme.themeData.copyWith(
      // Override specific theme properties if needed
      
      // Example: Custom bottom navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        indicatorColor: baseTheme.primaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Example: Custom app bar theme
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
      
      // Example: Custom button shapes
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
      
      // Example: Custom text button theme
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
    // Use the default dark theme as a base
    final baseDarkTheme = DeliverySystemTheme.defaultTheme().darkThemeData;
    
    // Customize for User App dark theme (if needed)
    return baseDarkTheme.copyWith(
      // Override specific theme properties if needed
      
      // Example: Custom bottom navigation bar theme for dark mode
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        indicatorColor: Colors.deepPurple.shade300.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Example: Custom app bar theme for dark mode
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
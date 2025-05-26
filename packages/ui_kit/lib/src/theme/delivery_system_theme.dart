import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Defines the main theme for the delivery system.
/// This theme supports white-labeling by allowing primary colors to be 
/// customized per client.
class DeliverySystemTheme {
  /// Primary brand color - can be customized per client
  final Color primaryColor;
  
  /// Secondary brand color - can be customized per client
  final Color secondaryColor;
  
  /// Accent color for call-to-actions
  final Color accentColor;
  
  /// Background color for the app
  final Color backgroundColor;
  
  /// Surface color for cards and elevated surfaces
  final Color surfaceColor;
  
  /// Error color for error states
  final Color errorColor;
  
  /// Success color for success states
  final Color successColor;
  
  /// Warning color for warning states
  final Color warningColor;
  
  /// Font family for the app - defaults to Poppins
  final String fontFamily;

  /// Creates a theme configuration with client-specific colors
  const DeliverySystemTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.backgroundColor = const Color(0xFFF9FAFB),
    this.surfaceColor = Colors.white,
    this.errorColor = const Color(0xFFE53935),
    this.successColor = const Color(0xFF43A047),
    this.warningColor = const Color(0xFFFF9800),
    this.fontFamily = 'Poppins',
  });

  /// Default theme with a blue color scheme
  factory DeliverySystemTheme.defaultTheme() {
    return const DeliverySystemTheme(
      primaryColor: Color(0xFF2563EB), // Blue
      secondaryColor: Color(0xFF1E40AF), // Darker blue
      accentColor: Color(0xFF10B981), // Green
    );
  }

  /// Get a configured ThemeData object based on theme colors
  ThemeData get themeData {
    return ThemeData(
      // Base colors
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        background: backgroundColor,
        surface: surfaceColor,
        brightness: Brightness.light,
      ),
      
      // Color for scaffolds and app background
      scaffoldBackgroundColor: backgroundColor,
      
      // Typography
      textTheme: _getTextTheme(),
      
      // Component themes
      appBarTheme: _getAppBarTheme(),
      cardTheme: _getCardTheme(),
      elevatedButtonTheme: _getElevatedButtonTheme(),
      outlinedButtonTheme: _getOutlinedButtonTheme(),
      textButtonTheme: _getTextButtonTheme(),
      inputDecorationTheme: _getInputDecorationTheme(),
      
      // Material 3 enabled
      useMaterial3: true,
    );
  }

  /// Generates a dark theme variant based on the light theme colors
  ThemeData get darkThemeData {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        brightness: Brightness.dark,
      ),
      textTheme: _getTextTheme(isDark: true),
      appBarTheme: _getAppBarTheme(isDark: true),
      elevatedButtonTheme: _getElevatedButtonTheme(),
      outlinedButtonTheme: _getOutlinedButtonTheme(isDark: true),
      textButtonTheme: _getTextButtonTheme(),
      inputDecorationTheme: _getInputDecorationTheme(isDark: true),
    );
  }

  // Private methods to generate component themes
  
  TextTheme _getTextTheme({bool isDark = false}) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: isDark ? Colors.white70 : Colors.black54,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: isDark ? Colors.white : Colors.black87,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: isDark ? Colors.white60 : Colors.black54,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: isDark ? Colors.white : primaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  AppBarTheme _getAppBarTheme({bool isDark = false}) {
    return AppBarTheme(
      backgroundColor: isDark ? Colors.grey[900] : surfaceColor,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: _getTextTheme(isDark: isDark).titleLarge,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  CardThemeData _getCardTheme() {
    return CardThemeData(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(8),
    );
  }

  ElevatedButtonThemeData _getElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        minimumSize: const Size(120, 48),
      ),
    );
  }

  OutlinedButtonThemeData _getOutlinedButtonTheme({bool isDark = false}) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        minimumSize: const Size(120, 48),
      ),
    );
  }

  TextButtonThemeData _getTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  InputDecorationTheme _getInputDecorationTheme({bool isDark = false}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: errorColor,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: errorColor,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      errorStyle: TextStyle(
        color: errorColor,
        fontSize: 12,
      ),
    );
  }
}
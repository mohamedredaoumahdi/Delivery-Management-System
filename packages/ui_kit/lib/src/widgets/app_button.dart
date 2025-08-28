import 'package:flutter/material.dart';

/// Button sizes available in the app
enum AppButtonSize {
  small,
  medium,
  large,
}

/// Button variants available in the app
enum AppButtonVariant {
  primary,
  secondary,
  outline,
  text,
}

/// A custom button component that follows the app's design system
class AppButton extends StatelessWidget {
  /// The text to display on the button
  final String text;

  /// The callback when the button is pressed
  final VoidCallback? onPressed;

  /// Optional icon to display before the text
  final IconData? icon;

  /// The size of the button
  final AppButtonSize size;

  /// The variant of the button
  final AppButtonVariant variant;

  /// Whether the button should take up the full width
  final bool fullWidth;

  /// Whether the button is in a loading state
  final bool isLoading;

  /// Optional border radius override
  final double? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = false,
    this.isLoading = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Get the theme colors
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final colorScheme = theme.colorScheme;
    
    // Determine button attributes based on variant and size
    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;
    
    // Determine colors based on button variant
    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = primaryColor;
        textColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = colorScheme.secondary;
        textColor = Colors.white;
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = primaryColor;
        borderSide = BorderSide(color: primaryColor, width: 2);
        break;
      case AppButtonVariant.text:
        backgroundColor = Colors.transparent;
        textColor = primaryColor;
        break;
    }
    
    // Determine size dimensions
    EdgeInsets padding;
    double height;
    double iconSize;
    double fontSize;
    
    switch (size) {
      case AppButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        height = 36;
        iconSize = 16;
        fontSize = 14;
        break;
      case AppButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        height = 48;
        iconSize = 18;
        fontSize = 16;
        break;
      case AppButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
        height = 56;
        iconSize = 20;
        fontSize = 18;
        break;
    }
    
    // Create the button style
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return backgroundColor.withValues(alpha:0.5);
        }
        if (variant == AppButtonVariant.text || variant == AppButtonVariant.outline) {
          if (states.contains(WidgetState.hovered) || 
              states.contains(WidgetState.pressed)) {
            return backgroundColor.withValues(alpha:0.1);
          }
          return backgroundColor;
        }
        if (states.contains(WidgetState.pressed)) {
          return backgroundColor.withValues(alpha:0.8);
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return textColor.withValues(alpha:0.5);
        }
        return textColor;
      }),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (variant == AppButtonVariant.text || variant == AppButtonVariant.outline) {
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withValues(alpha:0.04);
          }
          if (states.contains(WidgetState.focused)) {
            return primaryColor.withValues(alpha:0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withValues(alpha:0.12);
          }
        }
        return null;
      }),
      side: WidgetStateProperty.all(borderSide),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
      ),
      padding: WidgetStateProperty.all(padding),
      minimumSize: WidgetStateProperty.all(Size(fullWidth ? double.infinity : 0, height)),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    
    // Create button content
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              icon,
              size: iconSize,
            ),
          ),
        Text(text),
      ],
    );
    
    // Add invisible loading indicator when not loading for a smoother transition
    if (fullWidth && !isLoading && icon == null) {
      buttonContent = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: iconSize,
              height: iconSize,
            ),
          ),
          buttonContent,
        ],
      );
    }
    
    // Create the appropriate button type based on variant
    if (variant == AppButtonVariant.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonContent,
      );
    } else {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonContent,
      );
    }
  }
}
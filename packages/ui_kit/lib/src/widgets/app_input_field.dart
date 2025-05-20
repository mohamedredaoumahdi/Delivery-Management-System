import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom input field that follows the app's design system
class AppInputField extends StatelessWidget {
  /// Optional controller for the text field
  final TextEditingController? controller;
  
  /// The label text for the field
  final String? labelText;
  
  /// The hint text for the field
  final String? hintText;
  
  /// Error text to display (null if no error)
  final String? errorText;
  
  /// Prefix icon for the field
  final IconData? prefixIcon;
  
  /// Suffix icon for the field
  final IconData? suffixIcon;
  
  /// Callback when the suffix icon is pressed
  final VoidCallback? onSuffixIconPressed;
  
  /// The keyboard type for the field
  final TextInputType keyboardType;
  
  /// Whether the field is obscured (for passwords)
  final bool obscureText;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Whether the field is required
  final bool required;
  
  /// Input formatters for the field
  final List<TextInputFormatter>? inputFormatters;
  
  /// Validator function
  final String? Function(String?)? validator;
  
  /// On changed callback
  final Function(String)? onChanged;
  
  /// On submit callback
  final Function(String)? onSubmitted;
  
  /// Focus node for the field
  final FocusNode? focusNode;
  
  /// Max lines for the field
  final int? maxLines;
  
  /// Min lines for the field
  final int? minLines;
  
  /// Max length for the field
  final int? maxLength;

  const AppInputField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.required = false,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine prefix icon if needed
    Widget? prefix;
    if (prefixIcon != null) {
      prefix = Icon(
        prefixIcon,
        size: 20,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      );
    }
    
    // Determine suffix icon if needed
    Widget? suffix;
    if (suffixIcon != null) {
      suffix = IconButton(
        icon: Icon(
          suffixIcon,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        onPressed: onSuffixIconPressed,
        splashRadius: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }
    
    // Build the label text
    String? label = labelText;
    if (labelText != null && required) {
      label = '$labelText *';
    }
    
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefix != null ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: prefix,
        ) : null,
        suffixIcon: suffix != null ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: suffix,
        ) : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40, 
          minHeight: 40,
        ),
        isDense: true,
        filled: true,
        fillColor: enabled 
            ? theme.inputDecorationTheme.fillColor
            : theme.disabledColor.withOpacity(0.1),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: enabled 
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}
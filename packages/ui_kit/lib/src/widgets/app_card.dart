import 'package:flutter/material.dart';

/// A custom card component that follows the app's design system
class AppCard extends StatelessWidget {
  /// The child widget to display within the card
  final Widget child;
  
  /// Optional title for the card
  final String? title;
  
  /// Optional subtitle for the card
  final String? subtitle;
  
  /// Optional leading widget (usually an icon)
  final Widget? leading;
  
  /// Optional trailing widget
  final Widget? trailing;
  
  /// Content padding (defaults to 16)
  final EdgeInsetsGeometry contentPadding;
  
  /// Header padding (defaults to 16 horizontal, 12 vertical)
  final EdgeInsetsGeometry headerPadding;
  
  /// Border radius (defaults to 12)
  final double borderRadius;
  
  /// Elevation (defaults to 1)
  final double elevation;
  
  /// Whether to show a divider between header and content
  final bool showDivider;
  
  /// Whether the card is selectable/tappable
  final bool selectable;
  
  /// Callback when the card is tapped (if selectable)
  final VoidCallback? onTap;
  
  /// Optional background color (uses surface color from theme by default)
  final Color? backgroundColor;
  
  /// Optional border color
  final Color? borderColor;
  
  /// Optional border width (0 means no border)
  final double borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.contentPadding = const EdgeInsets.all(16),
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 12,
    this.elevation = 1,
    this.showDivider = false,
    this.selectable = false,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeader = title != null || subtitle != null || leading != null || trailing != null;
    
    // Build header if needed
    Widget? header;
    if (hasHeader) {
      header = Padding(
        padding: headerPadding,
        child: Row(
          children: [
            if (leading != null) 
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: leading!,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (subtitle != null)
                    Padding(
                      padding: title != null ? const EdgeInsets.only(top: 2) : EdgeInsets.zero,
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
    }
    
    // Build the card content
    final cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header,
        if (header != null && showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withValues(alpha:0.5),
          ),
        Flexible(
          child: Padding(
            padding: contentPadding,
            child: child,
          ),
        ),
      ],
    );
    
    // Build the card with proper decoration
    final card = Material(
      color: backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: elevation,
      clipBehavior: Clip.antiAlias,
      borderRadius: borderWidth > 0 ? null : BorderRadius.circular(borderRadius),
      shape: borderWidth > 0 
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide(
                color: borderColor ?? theme.dividerColor,
                width: borderWidth,
              ),
            )
          : null,
      child: cardContent,
    );
    
    // Wrap in InkWell if selectable
    if (selectable) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }
    
    return card;
  }
}
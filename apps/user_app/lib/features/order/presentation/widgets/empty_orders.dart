import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';

class EmptyOrders extends StatelessWidget {
  final String message;
  final String subMessage;

  const EmptyOrders({
    super.key,
    required this.message,
    required this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Browse Shops',
              onPressed: () {
                context.go('/shops');
              },
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              icon: Icons.store,
            ),
          ],
        ),
      ),
    );
  }
}
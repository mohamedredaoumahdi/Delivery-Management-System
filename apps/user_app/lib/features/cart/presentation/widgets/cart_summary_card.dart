import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

import '../domain/cart_repository.dart';

class CartSummaryCard extends StatelessWidget {
  final CartSummary summary;
  final VoidCallback onCheckout;

  const CartSummaryCard({
    super.key,
    required this.summary,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary items
            _buildSummaryRow(
              context,
              'Subtotal',
              '\$${summary.subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              'Delivery Fee',
              '\$${summary.deliveryFee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              'Service Fee',
              '\$${summary.serviceFee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              'Tax',
              '\$${summary.tax.toStringAsFixed(2)}',
            ),
            const Divider(height: 24),

            // Total
            _buildSummaryRow(
              context,
              'Total',
              '\$${summary.total.toStringAsFixed(2)}',
              isTotal: true,
            ),
            const SizedBox(height: 16),

            // Checkout button
            AppButton(
              text: 'Proceed to Checkout',
              onPressed: onCheckout,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.large,
              fullWidth: true,
              icon: Icons.shopping_cart_checkout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.bodyLarge,
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:domain/domain.dart';

class DeliveryProgress extends StatelessWidget {
  final OrderStatus status;

  const DeliveryProgress({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Define the progress steps
    final steps = [
      const _ProgressStep(
        title: 'Order Placed',
        subtitle: 'We received your order',
        icon: Icons.receipt_outlined,
        status: OrderStatus.pending,
      ),
      const _ProgressStep(
        title: 'Confirmed',
        subtitle: 'Shop accepted your order',
        icon: Icons.check_circle_outline,
        status: OrderStatus.accepted,
      ),
      const _ProgressStep(
        title: 'Preparing',
        subtitle: 'Your order is being prepared',
        icon: Icons.restaurant_outlined,
        status: OrderStatus.preparing,
      ),
      const _ProgressStep(
        title: 'Ready for Pickup',
        subtitle: 'Order is ready for delivery',
        icon: Icons.shopping_bag_outlined,
        status: OrderStatus.readyForPickup,
      ),
      const _ProgressStep(
        title: 'Out for Delivery',
        subtitle: 'Driver is on the way',
        icon: Icons.delivery_dining,
        status: OrderStatus.inDelivery,
      ),
      const _ProgressStep(
        title: 'Delivered',
        subtitle: 'Order delivered successfully',
        icon: Icons.check_circle,
        status: OrderStatus.delivered,
      ),
    ];

    return Column(
      children: [
        // Progress indicator
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _getProgressPercentage(),
            child: Container(
              decoration: BoxDecoration(
                color: _getProgressColor(theme),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Progress steps
        ...steps.map((step) => _buildProgressStep(context, step)),
      ],
    );
  }

  Widget _buildProgressStep(BuildContext context, _ProgressStep step) {
    final theme = Theme.of(context);
    final isCompleted = _isStepCompleted(step.status);
    final isCurrent = step.status == status;
    final isActive = isCompleted || isCurrent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Step icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              color: isActive 
                  ? Colors.white 
                  : theme.colorScheme.onSurface.withValues(alpha:0.4),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Step content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive 
                        ? theme.colorScheme.onSurface 
                        : theme.colorScheme.onSurface.withValues(alpha:0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isActive 
                        ? theme.colorScheme.onSurface.withValues(alpha:0.7) 
                        : theme.colorScheme.onSurface.withValues(alpha:0.4),
                  ),
                ),
              ],
            ),
          ),
          
          // Status indicator
          if (isCompleted)
            Icon(
              Icons.check,
              color: theme.colorScheme.primary,
              size: 20,
            )
          else if (isCurrent)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  bool _isStepCompleted(OrderStatus stepStatus) {
    const statusOrder = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.readyForPickup,
      OrderStatus.inDelivery,
      OrderStatus.delivered,
    ];

    final currentIndex = statusOrder.indexOf(status);
    final stepIndex = statusOrder.indexOf(stepStatus);

    return currentIndex > stepIndex;
  }

  double _getProgressPercentage() {
    switch (status) {
      case OrderStatus.pending:
        return 0.0;
      case OrderStatus.accepted:
        return 0.2;
      case OrderStatus.preparing:
        return 0.4;
      case OrderStatus.readyForPickup:
        return 0.6;
      case OrderStatus.inDelivery:
        return 0.8;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return 0.0;
    }
  }

  Color _getProgressColor(ThemeData theme) {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }
}

class _ProgressStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final OrderStatus status;

  const _ProgressStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
  });
}
import 'package:flutter/material.dart';
import 'package:domain/domain.dart';

class OrderStatusTimeline extends StatelessWidget {
  final Order order;

  const OrderStatusTimeline({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeline(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final steps = _getOrderSteps();
    final currentStepIndex = _getCurrentStepIndex();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isCompleted = index <= currentStepIndex;
        final isCurrent = index == currentStepIndex;
        
        return _buildTimelineStep(
          context,
          step,
          isCompleted,
          isCurrent,
          isLast: index == steps.length - 1,
        );
      },
    );
  }

  Widget _buildTimelineStep(
    BuildContext context,
    TimelineStep step,
    bool isCompleted,
    bool isCurrent,
    {required bool isLast}
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                border: isCurrent
                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: isCompleted || isCurrent
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (step.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  step.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              if (step.timestamp != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(step.timestamp!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<TimelineStep> _getOrderSteps() {
    final steps = <TimelineStep>[];
    
    // Order placed
    steps.add(TimelineStep(
      title: 'Order Placed',
      subtitle: 'Your order has been received',
      timestamp: order.createdAt,
    ));
    
    // Order accepted
    if (order.status.index >= OrderStatus.accepted.index) {
      steps.add(TimelineStep(
        title: 'Order Accepted',
        subtitle: 'Restaurant has accepted your order',
        timestamp: order.updatedAt,
      ));
    }
    
    // Preparing
    if (order.status.index >= OrderStatus.preparing.index) {
      steps.add(TimelineStep(
        title: 'Preparing',
        subtitle: 'Your food is being prepared',
        timestamp: order.updatedAt,
      ));
    }
    
    // Ready for pickup
    if (order.status.index >= OrderStatus.readyForPickup.index) {
      steps.add(TimelineStep(
        title: 'Ready for Pickup',
        subtitle: 'Your order is ready for delivery',
        timestamp: order.updatedAt,
      ));
    }
    
    // In delivery
    if (order.status.index >= OrderStatus.inDelivery.index) {
      steps.add(TimelineStep(
        title: 'In Delivery',
        subtitle: 'Your order is on the way',
        timestamp: order.updatedAt,
      ));
    }
    
    // Delivered
    if (order.status == OrderStatus.delivered) {
      steps.add(TimelineStep(
        title: 'Delivered',
        subtitle: 'Your order has been delivered',
        timestamp: order.deliveredAt ?? order.updatedAt,
      ));
    }
    
    // Cancelled
    if (order.status == OrderStatus.cancelled) {
      steps.add(TimelineStep(
        title: 'Cancelled',
        subtitle: 'Order was cancelled',
        timestamp: order.updatedAt,
      ));
    }
    
    return steps;
  }

  int _getCurrentStepIndex() {
    switch (order.status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.readyForPickup:
        return 3;
      case OrderStatus.inDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return 5; // Show cancelled step
      default:
        return 0;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

class TimelineStep {
  final String title;
  final String? subtitle;
  final DateTime? timestamp;

  TimelineStep({
    required this.title,
    this.subtitle,
    this.timestamp,
  });
}

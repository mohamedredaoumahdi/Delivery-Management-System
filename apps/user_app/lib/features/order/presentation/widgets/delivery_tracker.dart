import 'package:flutter/material.dart';
import 'package:domain/domain.dart';

class DeliveryTracker extends StatelessWidget {
  final Order order;

  const DeliveryTracker({
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
            Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delivery Tracker',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Delivery person info
            if (order.deliveryPersonId != null) ...[
              _buildDeliveryPersonInfo(context),
              const SizedBox(height: 16),
            ],
            
            // ETA info
            if (order.estimatedDeliveryTime != null) ...[
              _buildETAInfo(context),
              const SizedBox(height: 16),
            ],
            
            // Delivery address
            _buildDeliveryAddress(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPersonInfo(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.person,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Person',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ID: ${order.deliveryPersonId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            // TODO: Implement call delivery person
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Call feature coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.message),
          onPressed: () {
            // TODO: Implement message delivery person
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message feature coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildETAInfo(BuildContext context) {
    final theme = Theme.of(context);
    final eta = order.estimatedDeliveryTime!;
    final now = DateTime.now();
    final difference = eta.difference(now);
    
    String etaText;
    Color etaColor;
    
    if (difference.isNegative) {
      etaText = 'Delivered';
      etaColor = Colors.green;
    } else if (difference.inMinutes < 5) {
      etaText = 'Arriving soon';
      etaColor = Colors.orange;
    } else {
      etaText = '${difference.inMinutes} minutes';
      etaColor = theme.colorScheme.primary;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: etaColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: etaColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: etaColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Delivery',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  etaText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: etaColor,
                  ),
                ),
              ],
            ),
          ),
          if (difference.isNegative) ...[
            Icon(
              Icons.check_circle,
              color: etaColor,
              size: 20,
            ),
          ] else ...[
            CircularProgressIndicator(
              value: _calculateProgress(),
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(etaColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Address',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                order.deliveryAddress,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.directions),
          onPressed: () {
            // TODO: Implement open in maps
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maps integration coming soon')),
            );
          },
        ),
      ],
    );
  }

  double _calculateProgress() {
    if (order.estimatedDeliveryTime == null) return 0.0;
    
    final now = DateTime.now();
    final estimatedTime = order.estimatedDeliveryTime!;
    final orderTime = order.createdAt;
    
    final totalDuration = estimatedTime.difference(orderTime);
    final elapsedDuration = now.difference(orderTime);
    
    if (totalDuration.inSeconds <= 0) return 1.0;
    
    final progress = elapsedDuration.inSeconds / totalDuration.inSeconds;
    return progress.clamp(0.0, 1.0);
  }
}

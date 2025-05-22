import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

class OrderListItem extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onTrack;

  const OrderListItem({
    super.key,
    required this.order,
    required this.onTap,
    this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return AppCard(
      contentPadding: const EdgeInsets.all(16),
      selectable: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID, Status and Date
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(order.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context, order.status),
            ],
          ),
          const Divider(height: 24),
          
          // Shop info and items count
          Row(
            children: [
              // Shop icon or logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.storefront,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              
              // Shop name and order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.shopName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.totalItems} ${order.totalItems == 1 ? 'item' : 'items'} - \$${order.total.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Actions based on order status
          if (onTrack != null || order.canBeCancelled || order.status == OrderStatus.delivered)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button for orders that can be cancelled
                  if (order.canBeCancelled)
                    TextButton(
                      onPressed: () {
                        _showCancelDialog(context, order.id);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: const Text('Cancel'),
                    ),
                  
                  // Track button for orders in delivery
                  if (onTrack != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onTrack,
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text('Track'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  
                  // Reorder button for completed orders
                  if (order.status == OrderStatus.delivered) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Handle reorder
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reorder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, OrderStatus status) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    String statusText;
    
    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        statusText = 'Pending';
        break;
      case OrderStatus.accepted:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        statusText = 'Accepted';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
        statusText = 'Preparing';
        break;
      case OrderStatus.readyForPickup:
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade900;
        statusText = 'Ready';
        break;
      case OrderStatus.inDelivery:
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        statusText = 'In Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        statusText = 'Cancelled';
        break;
      case OrderStatus.refunded:
        backgroundColor = Colors.blueGrey.shade100;
        textColor = Colors.blueGrey.shade900;
        statusText = 'Refunded';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // Show cancel order confirmation dialog
  void _showCancelDialog(BuildContext context, String orderId) {
    final orderBloc = context.read<OrderBloc>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              orderBloc.add(OrderCancelEvent(orderId: orderId));
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
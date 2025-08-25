import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:domain/domain.dart';

import '../bloc/order_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(OrderLoadDetailsEvent(widget.orderId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoadingDetails) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is OrderDetailsLoaded) {
            final order = state.order;
            return _buildOrderDetails(context, order);
          } else if (state is OrderError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load order details',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrderBloc>().add(
                            OrderLoadDetailsEvent(widget.orderId),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          // Default loading state
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy - h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(order.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context, order.status),
            ],
          ),
          const SizedBox(height: 24),
          
          // Shop Info
          AppCard(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://via.placeholder.com/48', // Replace with actual shop logo
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  color: theme.colorScheme.primary,
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            title: order.shopName,
            subtitle: 'View Shop',
            onTap: () {
              context.push('/shops/${order.shopId}');
            },
            child: const SizedBox(),
          ),
          const SizedBox(height: 24),
          
          // Order Items
          Text(
            'Order Items',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => _buildOrderItem(context, item)),
          const SizedBox(height: 24),
          
          // Order Summary
          Text(
            'Order Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                _buildSummaryRow(context, 'Subtotal', '\$${order.subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Delivery Fee', '\$${order.deliveryFee.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Service Fee', '\$${order.serviceFee.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Tax', '\$${order.tax.toStringAsFixed(2)}'),
                
                if (order.tip > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(context, 'Tip', '\$${order.tip.toStringAsFixed(2)}'),
                ],
                
                if (order.discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    context,
                    'Discount',
                    '-\$${order.discount.toStringAsFixed(2)}',
                    valueColor: Colors.green,
                  ),
                ],
                
                const Divider(height: 24),
                _buildSummaryRow(
                  context,
                  'Total',
                  '\$${order.total.toStringAsFixed(2)}',
                  isTotal: true,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  context,
                  'Payment Method',
                  _getPaymentMethodName(order.paymentMethod),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Delivery Information
          Text(
            'Delivery Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context, Icons.location_on_outlined, 'Address', order.deliveryAddress),
                
                if (order.deliveryInstructions?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.info_outline,
                    'Instructions',
                    order.deliveryInstructions!,
                  ),
                ],
                
                if (order.estimatedDeliveryTime != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.access_time,
                    'Estimated Delivery',
                    dateFormat.format(order.estimatedDeliveryTime!),
                  ),
                ],
                
                if (order.deliveredAt != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.check_circle_outline,
                    'Delivered At',
                    dateFormat.format(order.deliveredAt!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Action buttons
          if (order.status == OrderStatus.inDelivery)
            AppButton(
              text: 'Track Order',
              icon: Icons.location_on,
              onPressed: () {
                context.push('/orders/${order.id}/tracking');
              },
              variant: AppButtonVariant.primary,
              fullWidth: true,
            ),
          
          if (order.status == OrderStatus.delivered)
            AppButton(
              text: 'Reorder',
              icon: Icons.refresh,
              onPressed: () {
                _handleReorder(context, order);
              },
              variant: AppButtonVariant.primary,
              fullWidth: true,
            ),
            
          if (order.canBeCancelled) ...[
            const SizedBox(height: 16),
            AppButton(
              text: 'Cancel Order',
              icon: Icons.cancel_outlined,
              onPressed: () {
                _showCancelDialog(context, order.id);
              },
              variant: AppButtonVariant.outline,
              fullWidth: true,
            ),
          ],
          
          const SizedBox(height: 16),
          AppButton(
            text: 'Need Help?',
            icon: Icons.help_outline,
            onPressed: () {
              // Handle help request
            },
            variant: AppButtonVariant.text,
            fullWidth: true,
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
        statusText = 'Ready for Pickup';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildOrderItem(BuildContext context, OrderItem item) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        contentPadding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quantity
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.quantity}x',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  if (item.instructions?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Instructions: ${item.instructions}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.productPrice.toStringAsFixed(2)} each',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                  ),
                ),
              ],
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
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
  
  void _showCancelDialog(BuildContext context, String orderId) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Tell us why you\'re cancelling',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep Order'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<OrderBloc>().add(
                    OrderCancelEvent(
                      orderId: orderId,
                      reason: reasonController.text.trim().isNotEmpty
                          ? reasonController.text.trim()
                          : null,
                    ),
                  );
            },
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    ).then((_) => reasonController.dispose());
  }

  void _handleReorder(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reorder Items?'),
        content: Text(
          'This will add all items from this order to your cart. '
          'Any existing cart items will be cleared first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _processReorder(context, order);
            },
            child: const Text('Reorder'),
          ),
        ],
      ),
    );
  }

  Future<void> _processReorder(BuildContext context, Order order) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Adding items to cart...'),
            ],
          ),
        ),
      );

      // Clear existing cart first
      context.read<CartBloc>().add(const CartClearEvent());

      // Add each item from the order to the cart
      for (final item in order.items) {
        // We need to create a Product object from the OrderItem
        // Note: In a real app, you might want to fetch fresh product data
        final product = Product(
          id: item.productId,
          shopId: order.shopId,
          name: item.productName,
          description: '', // Not available in OrderItem
          price: item.productPrice,
          imageUrl: null, // Not available in OrderItem
          category: '', // Not available in OrderItem
          inStock: true, // Assume in stock for reorder
          isFeatured: false,
          rating: 0.0,
          ratingCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        context.read<CartBloc>().add(
          CartAddItemEvent(
            product: product,
            shopId: order.shopId,
            shopName: order.shopName,
            quantity: item.quantity,
            instructions: item.instructions,
          ),
        );
      }

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${order.items.length} items added to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () => context.go('/cart'),
          ),
        ),
      );

      // Optionally navigate to cart or checkout
      context.go('/cart');

    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context, rootNavigator: true).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reorder: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
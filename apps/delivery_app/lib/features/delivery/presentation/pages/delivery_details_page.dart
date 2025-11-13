import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core/core.dart';
import 'package:get_it/get_it.dart';

import '../bloc/delivery_bloc.dart';
import '../../../earnings/presentation/bloc/earnings_bloc.dart';

class DeliveryDetailsPage extends StatefulWidget {
  final String deliveryId;

  const DeliveryDetailsPage({
    super.key,
    required this.deliveryId,
  });

  @override
  State<DeliveryDetailsPage> createState() => _DeliveryDetailsPageState();
}

class _DeliveryDetailsPageState extends State<DeliveryDetailsPage> {
  late final LoggerService _logger;

  @override
  void initState() {
    super.initState();
    _logger = GetIt.instance<LoggerService>();
    context.read<DeliveryBloc>().add(DeliveryLoadDetailsEvent(widget.deliveryId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.deliveryId}'),
        elevation: 0,
      ),
      body: BlocListener<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Delivery accepted! You can now start the delivery.'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back to dashboard instead of navigation page
            Future.delayed(const Duration(seconds: 2), () {
              try {
                if (context.mounted) {
                  context.go('/dashboard');
                }
              } catch (e) {
                _logger.e('❌ Navigation error: $e');
                // Fallback navigation
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            });
          } else if (state is DeliveryStatusUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status updated to ${state.status.name}'),
                backgroundColor: Colors.blue,
              ),
            );
          } else if (state is DeliveryMarkedAsDelivered) {
            // Order was just marked as delivered
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order marked as delivered successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Trigger refresh of deliveries list and earnings before navigating back
            // This ensures the list and earnings are updated when we return
            context.read<DeliveryBloc>().add(const DeliveryLoadAssignedEvent());
            // Refresh earnings to reflect the new delivery
            try {
              final earningsBloc = context.read<EarningsBloc>();
              earningsBloc.add(const EarningsRefreshEvent());
            } catch (e) {
              _logger.w('⚠️ Could not refresh earnings: $e');
            }
            // Navigate back to deliveries list
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          } else if (state is DeliveryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<DeliveryBloc, DeliveryState>(
          builder: (context, state) {
            if (state is DeliveryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DeliveryError) {
              _logger.e('❌ DeliveryDetailsPage: Showing error view: ${state.message}');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load delivery details',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message.contains('timeout') 
                          ? 'The request took longer than expected. Please check your connection and try again.'
                          : state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _logger.i('🔄 DeliveryDetailsPage: Retry button pressed');
                          context.read<DeliveryBloc>().add(DeliveryLoadDetailsEvent(widget.deliveryId));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: const Text('Try Again'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          _logger.i('🔙 DeliveryDetailsPage: Go back button pressed');
                          Navigator.of(context).pop();
                        },
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is DeliveryDetailsLoaded) {
              return _buildDeliveryDetails(context, state.delivery);
            }

            // Show loading state if no other state matches
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails(BuildContext context, DeliveryOrder delivery) {
    final earnings = _calculateEarnings(delivery.total, delivery.distance);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and Earnings Card
          _buildStatusCard(context, delivery, earnings),
          const SizedBox(height: 16),

          // Customer Information Card
          _buildCustomerCard(context, delivery),
          const SizedBox(height: 16),

          // Delivery Information Card
          _buildDeliveryInfoCard(context, delivery),
          const SizedBox(height: 16),

          // Order Items Card
          _buildOrderItemsCard(context, delivery),
          const SizedBox(height: 16),

          // Payment Information Card
          _buildPaymentCard(context, delivery, earnings),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(context, delivery),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, DeliveryOrder delivery, double earnings) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(delivery.status);
    final statusText = _getStatusText(delivery.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${earnings.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated Earnings',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, DeliveryOrder delivery) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.customerName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (delivery.customerPhone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          delivery.customerPhone!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'No phone number available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: delivery.customerPhone != null
                      ? () => _callCustomer(delivery.customerPhone!)
                      : null,
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: delivery.customerPhone != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  tooltip: delivery.customerPhone != null ? 'Call Customer' : 'Phone number not available',
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: delivery.customerPhone != null
                      ? () => _messageCustomer(delivery.customerPhone!)
                      : null,
                  icon: const Icon(Icons.message),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    foregroundColor: delivery.customerPhone != null
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  tooltip: delivery.customerPhone != null ? 'Message Customer' : 'Phone number not available',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard(BuildContext context, DeliveryOrder delivery) {
    final theme = Theme.of(context);
    final estimatedTime = _calculateEstimatedTime(delivery.distance);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.location_on_outlined,
              'Delivery Address',
              delivery.deliveryAddress,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.local_shipping_outlined,
              'Distance',
              '${delivery.distance.toStringAsFixed(1)} km',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Estimated Time',
              estimatedTime,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.store_outlined,
              'Restaurant',
              delivery.shopName,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.location_on_outlined,
              'Pickup Address',
              delivery.pickupAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(BuildContext context, DeliveryOrder delivery) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (delivery.items.isEmpty)
              Text(
                'No items found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            else
              ...delivery.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, DeliveryOrder delivery, double earnings) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (delivery.paymentMethod != null) ...[
              Row(
                children: [
                  Icon(
                    delivery.paymentMethod == 'CASH_ON_DELIVERY' 
                        ? Icons.money 
                        : Icons.credit_card,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatPaymentMethod(delivery.paymentMethod!),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (delivery.paymentMethod != 'CASH_ON_DELIVERY')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PAID',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CASH',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],
            if (delivery.subtotal > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal:', style: theme.textTheme.bodyMedium),
                  Text('\$${delivery.subtotal.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (delivery.deliveryFee > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Fee:', style: theme.textTheme.bodyMedium),
                  Text('\$${delivery.deliveryFee.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (delivery.serviceFee > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Service Fee:', style: theme.textTheme.bodyMedium),
                  Text('\$${delivery.serviceFee.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (delivery.tax > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax:', style: theme.textTheme.bodyMedium),
                  Text('\$${delivery.tax.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (delivery.tip > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tip:', style: theme.textTheme.bodyMedium),
                  Text('\$${delivery.tip.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (delivery.discount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount:', style: theme.textTheme.bodyMedium),
                  Text('-\$${delivery.discount.toStringAsFixed(2)}', 
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${delivery.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, DeliveryOrder delivery) {
    if (delivery.status == DeliveryStatus.pending || delivery.status == DeliveryStatus.readyForPickup) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<DeliveryBloc>().add(DeliveryAcceptEvent(delivery.id));
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Accept Delivery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Available Deliveries'),
            ),
          ),
        ],
      );
    }

    // For active deliveries (picked up, in transit), show navigation and mark as delivered buttons
    if (delivery.status == DeliveryStatus.pickedUp || 
        delivery.status == DeliveryStatus.inTransit ||
        delivery.status == DeliveryStatus.accepted) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/navigation/${delivery.id}');
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showMarkDeliveredDialog(context, delivery);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Delivered'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // For delivered orders, just show navigation button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.go('/navigation/${delivery.id}');
        },
        icon: const Icon(Icons.navigation),
        label: const Text('View Navigation'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }



  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.readyForPickup:
        return Colors.blue;
      case DeliveryStatus.accepted:
        return Colors.green;
      case DeliveryStatus.pickedUp:
        return Colors.purple;
      case DeliveryStatus.inTransit:
        return Colors.indigo;
      case DeliveryStatus.delivered:
        return Colors.green;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'PENDING';
      case DeliveryStatus.readyForPickup:
        return 'READY FOR PICKUP';
      case DeliveryStatus.accepted:
        return 'ACCEPTED';
      case DeliveryStatus.pickedUp:
        return 'PICKED UP';
      case DeliveryStatus.inTransit:
        return 'IN TRANSIT';
      case DeliveryStatus.delivered:
        return 'DELIVERED';
    }
  }

  String _calculateEstimatedTime(double distance) {
    final minutes = (distance / 30 * 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }

  double _calculateEarnings(double orderTotal, double distance) {
    const baseDeliveryFee = 3.0;
    final distanceBonus = distance * 0.5;
    final orderPercentage = orderTotal * 0.02;
    return baseDeliveryFee + distanceBonus + orderPercentage;
  }

  String _formatPaymentMethod(String paymentMethod) {
    switch (paymentMethod.toUpperCase()) {
      case 'CASH_ON_DELIVERY':
        return 'Cash on Delivery';
      case 'CREDIT_CARD':
        return 'Credit Card';
      case 'DEBIT_CARD':
        return 'Debit Card';
      case 'PAYPAL':
        return 'PayPal';
      case 'STRIPE':
        return 'Stripe';
      default:
        return paymentMethod.replaceAll('_', ' ');
    }
  }

  void _callCustomer(String phoneNumber) async {
    // Remove any non-digit characters except +
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _messageCustomer(String phoneNumber) async {
    // Remove any non-digit characters except +
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri smsUri = Uri(scheme: 'sms', path: cleanedPhone);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  void _showMarkDeliveredDialog(BuildContext context, DeliveryOrder delivery) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark as Delivered',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confirm delivery completion',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Instruction text
              Text(
                'Please confirm that the order has been delivered successfully to the customer.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              
              // Order details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order Details',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDialogDetailRow(
                      context,
                      Icons.tag,
                      'Order Number',
                      '#${delivery.orderNumber}',
                    ),
                    const SizedBox(height: 8),
                    _buildDialogDetailRow(
                      context,
                      Icons.person,
                      'Customer',
                      delivery.customerName,
                    ),
                    const SizedBox(height: 8),
                    _buildDialogDetailRow(
                      context,
                      Icons.attach_money,
                      'Total Amount',
                      '\$${delivery.total.toStringAsFixed(2)}',
                      isHighlighted: true,
                    ),
                  ],
                ),
              ),
              
              // Cash payment warning
              if (delivery.paymentMethod == 'CASH_ON_DELIVERY') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash Payment Required',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Make sure to collect \$${delivery.total.toStringAsFixed(2)} from the customer before confirming delivery.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<DeliveryBloc>().add(DeliveryMarkDeliveredEvent(delivery.id));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text('Confirm Delivery'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isHighlighted
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  color: isHighlighted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontSize: isHighlighted ? 16 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 
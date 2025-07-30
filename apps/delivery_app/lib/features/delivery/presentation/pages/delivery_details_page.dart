import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/delivery_bloc.dart';

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
  @override
  void initState() {
    super.initState();
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
                content: Text('Delivery accepted! Redirecting to navigation...'),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(seconds: 1), () {
              context.go('/navigation/${widget.deliveryId}');
            });
          } else if (state is DeliveryStatusUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status updated to ${state.status.name}'),
                backgroundColor: Colors.blue,
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
              return _buildErrorView(context, state.message);
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

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Unable to load delivery details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<DeliveryBloc>().add(DeliveryLoadDetailsEvent(widget.deliveryId));
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails(BuildContext context, DeliveryOrder delivery) {
    final theme = Theme.of(context);
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
                      const SizedBox(height: 4),
                      Text(
                        '+1 (555) 123-4567',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _callCustomer(),
                  icon: const Icon(Icons.phone),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _messageCustomer(),
                  icon: const Icon(Icons.message),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.secondary,
                  ),
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
              'Golden Dragon Restaurant',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.location_on_outlined,
              'Pickup Address',
              '789 Food Court Ave, Downtown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(BuildContext context, DeliveryOrder delivery) {
    final theme = Theme.of(context);
    final mockItems = [
      {'name': 'Kung Pao Chicken', 'quantity': 2, 'price': 12.99},
      {'name': 'Fried Rice', 'quantity': 1, 'price': 8.99},
      {'name': 'Spring Rolls', 'quantity': 3, 'price': 6.99},
    ];

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
            ...mockItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${item['quantity']}x',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '\$${(item['price'] as double).toStringAsFixed(2)}',
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
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Credit Card •••• 4532',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal:', style: theme.textTheme.bodyMedium),
                Text('\$${(delivery.total - 2.99).toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Fee:', style: theme.textTheme.bodyMedium),
                Text('\$2.99', style: theme.textTheme.bodyMedium),
              ],
            ),
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
    final theme = Theme.of(context);

    if (delivery.status == DeliveryStatus.pending) {
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _callCustomer(),
                child: const Text('Call Customer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _messageCustomer(),
                child: const Text('Message'),
              ),
            ),
          ],
        ),
      ],
    );
  }



  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.accepted:
        return Colors.blue;
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
      return '${minutes} min';
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

  void _callCustomer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+15551234567');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _messageCustomer() async {
    final Uri smsUri = Uri(scheme: 'sms', path: '+15551234567');
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }
} 
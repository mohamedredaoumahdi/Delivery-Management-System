import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/delivery_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart' hide DeliveryOrder;

class AvailableDeliveriesPage extends StatefulWidget {
  const AvailableDeliveriesPage({super.key});

  @override
  State<AvailableDeliveriesPage> createState() => _AvailableDeliveriesPageState();
}

class _AvailableDeliveriesPageState extends State<AvailableDeliveriesPage> {
  @override
  void initState() {
    super.initState();
    print('🚀 AvailableDeliveriesPage: initState called');
    print('📡 AvailableDeliveriesPage: Adding DeliveryLoadAvailableEvent to bloc');
    context.read<DeliveryBloc>().add(const DeliveryLoadAvailableEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 AvailableDeliveriesPage: Refresh button pressed');
              print('📡 AvailableDeliveriesPage: Adding DeliveryLoadAvailableEvent to bloc');
              context.read<DeliveryBloc>().add(const DeliveryLoadAvailableEvent());
            },
          ),
        ],
      ),
      body: BlocListener<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          print('🎧 AvailableDeliveriesPage BlocListener: State changed to ${state.runtimeType}');
          
          if (state is DeliveryAccepted) {
            print('✅ AvailableDeliveriesPage: Delivery accepted successfully!');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Delivery accepted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            print('🔄 AvailableDeliveriesPage: Refreshing dashboard after acceptance');
            context.read<DashboardBloc>().add(const DashboardRefreshEvent());
          } else if (state is DeliveryError) {
            print('❌ AvailableDeliveriesPage: Delivery error occurred: ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to accept delivery: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is DeliveryLoading) {
            print('⏳ AvailableDeliveriesPage: Delivery loading state');
          }
        },
        child: BlocBuilder<DeliveryBloc, DeliveryState>(
          builder: (context, state) {
            print('🎨 AvailableDeliveriesPage: BlocBuilder triggered with state: ${state.runtimeType}');
            
            if (state is DeliveryLoading) {
              print('⏳ AvailableDeliveriesPage: Showing loading spinner');
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DeliveryError) {
              print('❌ AvailableDeliveriesPage: Showing error view with message: ${state.message}');
              return _buildErrorView(context, state.message);
            }

            if (state is DeliveryLoaded) {
              print('✅ AvailableDeliveriesPage: Showing delivery list with ${state.deliveries.length} deliveries');
              print('📦 AvailableDeliveriesPage: Deliveries: ${state.deliveries}');
              return _buildDeliveryList(context, state.deliveries);
            }

            print('⚠️ AvailableDeliveriesPage: Showing empty view (default case)');
            return _buildEmptyView(context);
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
              'Unable to load deliveries',
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
                context.read<DeliveryBloc>().add(const DeliveryLoadAvailableEvent());
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Available Deliveries',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new delivery opportunities.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                context.read<DeliveryBloc>().add(const DeliveryLoadAvailableEvent());
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryList(BuildContext context, List<DeliveryOrder> deliveries) {
    if (deliveries.isEmpty) {
      return _buildEmptyView(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DeliveryBloc>().add(const DeliveryLoadAvailableEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return _buildDeliveryCard(context, delivery);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, DeliveryOrder delivery) {
    final theme = Theme.of(context);
    final estimatedTime = _calculateEstimatedTime(delivery.distance);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with order number and earnings
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${delivery.orderNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${_calculateEarnings(delivery.total, delivery.distance).toStringAsFixed(2)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer info
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  delivery.customerName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Delivery address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delivery.deliveryAddress,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Delivery details row
            Row(
              children: [
                _buildDetailChip(
                  context,
                  Icons.local_shipping_outlined,
                  '${delivery.distance.toStringAsFixed(1)} km',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  context,
                  Icons.access_time,
                  estimatedTime,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  context,
                  Icons.attach_money,
                  '\$${delivery.total.toStringAsFixed(2)}',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.push('/delivery/${delivery.id}');
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showAcceptDialog(context, delivery);
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String label, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(BuildContext context, DeliveryOrder delivery) {
    final theme = Theme.of(context);
    final earnings = _calculateEarnings(delivery.total, delivery.distance);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Delivery?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: #${delivery.orderNumber}'),
            const SizedBox(height: 8),
            Text('Customer: ${delivery.customerName}'),
            const SizedBox(height: 8),
            Text('Distance: ${delivery.distance.toStringAsFixed(1)} km'),
            const SizedBox(height: 8),
            Text(
              'Estimated Earnings: \$${earnings.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('🚀 AvailableDeliveriesPage: Accept button pressed for delivery: ${delivery.id}');
              print('📦 AvailableDeliveriesPage: Delivery details: ${delivery.customerName}, ${delivery.deliveryAddress}');
              Navigator.of(context).pop();
              print('📡 AvailableDeliveriesPage: Adding DeliveryAcceptEvent to bloc');
              context.read<DeliveryBloc>().add(DeliveryAcceptEvent(delivery.id));
              print('✅ AvailableDeliveriesPage: DeliveryAcceptEvent added successfully');
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  String _calculateEstimatedTime(double distance) {
    // Estimate based on average speed of 30 km/h in city
    final minutes = (distance / 30 * 60).round();
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }

  double _calculateEarnings(double orderTotal, double distance) {
    // Base delivery fee + distance bonus + percentage of order
    const baseDeliveryFee = 3.0;
    final distanceBonus = distance * 0.5; // $0.50 per km
    final orderPercentage = orderTotal * 0.02; // 2% of order value
    return baseDeliveryFee + distanceBonus + orderPercentage;
  }
} 
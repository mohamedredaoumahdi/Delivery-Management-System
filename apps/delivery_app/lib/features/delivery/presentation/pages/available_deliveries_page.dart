import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/delivery_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart' hide DeliveryOrder, DeliveryStatus;

enum DeliveryTab { available, active, completed, all }

class AvailableDeliveriesPage extends StatefulWidget {
  const AvailableDeliveriesPage({super.key});

  @override
  State<AvailableDeliveriesPage> createState() => _AvailableDeliveriesPageState();
}

class _AvailableDeliveriesPageState extends State<AvailableDeliveriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DeliveryTab _currentTab = DeliveryTab.available;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadDeliveries();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    
    setState(() {
      _currentTab = DeliveryTab.values[_tabController.index];
    });
    _loadDeliveries();
  }

  void _loadDeliveries() {
    switch (_currentTab) {
      case DeliveryTab.available:
        context.read<DeliveryBloc>().add(const DeliveryLoadAvailableEvent());
        break;
      case DeliveryTab.active:
      case DeliveryTab.completed:
      case DeliveryTab.all:
        context.read<DeliveryBloc>().add(const DeliveryLoadAssignedEvent());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: BlocListener<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryAccepted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Delivery accepted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<DashboardBloc>().add(const DashboardRefreshEvent());
            _loadDeliveries();
          } else if (state is DeliveryMarkedAsDelivered) {
            // Order was marked as delivered, refresh the deliveries list
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order marked as delivered!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            context.read<DashboardBloc>().add(const DashboardRefreshEvent());
            _loadDeliveries();
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
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is DeliveryError) {
              return _buildErrorView(context, state.message);
            }

            if (state is DeliveryLoaded) {
              final filteredDeliveries = _filterDeliveries(state.deliveries);
              return _buildDeliveryList(context, filteredDeliveries);
            }

            return _buildEmptyView(context, 'No deliveries found');
          },
        ),
      ),
    );
  }

  List<DeliveryOrder> _filterDeliveries(List<DeliveryOrder> deliveries) {
    switch (_currentTab) {
      case DeliveryTab.available:
        return deliveries;
      case DeliveryTab.active:
        return deliveries.where((d) {
          return d.status == DeliveryStatus.accepted ||
              d.status == DeliveryStatus.pickedUp ||
              d.status == DeliveryStatus.inTransit ||
              d.status == DeliveryStatus.readyForPickup;
        }).toList();
      case DeliveryTab.completed:
        return deliveries.where((d) => d.status == DeliveryStatus.delivered).toList();
      case DeliveryTab.all:
        return deliveries;
    }
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
              onPressed: _loadDeliveries,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, String message) {
    final theme = Theme.of(context);
    final tabLabels = {
      DeliveryTab.available: 'No Available Deliveries',
      DeliveryTab.active: 'No Active Deliveries',
      DeliveryTab.completed: 'No Completed Deliveries',
      DeliveryTab.all: 'No Deliveries',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tabLabels[_currentTab] ?? 'No Deliveries',
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
            OutlinedButton(
              onPressed: _loadDeliveries,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryList(BuildContext context, List<DeliveryOrder> deliveries) {
    if (deliveries.isEmpty) {
      return _buildEmptyView(context, 'Check back later for new delivery opportunities.');
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadDeliveries();
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
    final statusColor = _getStatusColor(delivery.status);
    final statusText = _getStatusText(delivery.status);
    final showAcceptButton = _currentTab == DeliveryTab.available;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.push('/delivery/${delivery.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order number, status, and earnings
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(delivery.status),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${delivery.orderNumber.length > 7 ? delivery.orderNumber.substring(0, 7) : delivery.orderNumber}...',
                          style: TextStyle(
                            fontSize: theme.textTheme.titleMedium?.fontSize ?? 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: theme.textTheme.bodySmall?.fontSize ?? 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${_calculateEarnings(delivery.total, delivery.distance).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: theme.textTheme.titleMedium?.fontSize ?? 16,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer info
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      delivery.customerName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Delivery details row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDetailChip(
                    context,
                    Icons.local_shipping_outlined,
                    '${delivery.distance.toStringAsFixed(1)} km',
                    Colors.blue,
                  ),
                  _buildDetailChip(
                    context,
                    Icons.access_time,
                    estimatedTime,
                    Colors.orange,
                  ),
                  _buildDetailChip(
                    context,
                    Icons.attach_money,
                    '\$${delivery.total.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ],
              ),

              // Action buttons
              if (showAcceptButton) ...[
                const SizedBox(height: 16),
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
            ],
          ),
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

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
      case DeliveryStatus.readyForPickup:
        return Colors.orange;
      case DeliveryStatus.accepted:
        return Colors.blue;
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.inTransit:
        return Colors.purple;
      case DeliveryStatus.delivered:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
      case DeliveryStatus.readyForPickup:
        return Icons.schedule;
      case DeliveryStatus.accepted:
        return Icons.check_circle_outline;
      case DeliveryStatus.pickedUp:
      case DeliveryStatus.inTransit:
        return Icons.local_shipping;
      case DeliveryStatus.delivered:
        return Icons.check_circle;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.readyForPickup:
        return 'Ready';
      case DeliveryStatus.accepted:
        return 'Accepted';
      case DeliveryStatus.pickedUp:
        return 'Picked Up';
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
    }
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
              Navigator.of(context).pop();
              context.read<DeliveryBloc>().add(DeliveryAcceptEvent(delivery.id));
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

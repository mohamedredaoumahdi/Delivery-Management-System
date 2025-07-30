import 'package:delivery_app/features/location/presentation/bloc/location_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    print('🚀 DashboardPage: initState called');
    print('📡 DashboardPage: Adding DashboardLoadEvent');
    context.read<DashboardBloc>().add(const DashboardLoadEvent());
    print('📍 DashboardPage: Adding LocationCheckStatusEvent');
    context.read<LocationBloc>().add(const LocationCheckStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          BlocBuilder<LocationBloc, LocationState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state is LocationEnabled 
                      ? Icons.location_on 
                      : Icons.location_off,
                  color: state is LocationEnabled 
                      ? Colors.green 
                      : Colors.red,
                ),
                onPressed: () {
                  if (state is! LocationEnabled) {
                    context.read<LocationBloc>().add(const LocationEnableEvent());
                  }
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardBloc>().add(const DashboardRefreshEvent());
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            print('🎨 DashboardPage: BlocBuilder triggered with state: ${state.runtimeType}');
            
            if (state is DashboardLoading) {
              print('⏳ DashboardPage: Showing loading indicator');
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              print('❌ DashboardPage: Showing error view: ${state.message}');
              return _buildErrorView(context, state.message);
            }

            if (state is DashboardLoaded) {
              print('✅ DashboardPage: Showing dashboard content');
              print('📦 DashboardPage: Available deliveries count: ${state.availableDeliveries.length}');
              return _buildDashboardContent(context, state);
            }

            print('⚠️ DashboardPage: Showing empty view (default case)');
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            return FloatingActionButton.extended(
              onPressed: () {
                if (state.driverStatus == DriverStatus.offline) {
                  context.read<DashboardBloc>().add(const DashboardGoOnlineEvent());
                } else {
                  context.read<DashboardBloc>().add(const DashboardGoOfflineEvent());
                }
              },
              icon: Icon(
                state.driverStatus == DriverStatus.offline
                    ? Icons.power_settings_new
                    : Icons.stop,
              ),
              label: Text(
                state.driverStatus == DriverStatus.offline ? 'Go Online' : 'Go Offline',
              ),
              backgroundColor: state.driverStatus == DriverStatus.offline
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            );
          }
          return const SizedBox.shrink();
        },
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
              'Unable to load dashboard',
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
                context.read<DashboardBloc>().add(const DashboardLoadEvent());
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver Status Card
          _buildStatusCard(context, state),
          const SizedBox(height: 16),
          
          // Quick Stats
          _buildQuickStats(context, state),
          const SizedBox(height: 16),
          
          // Available Deliveries
          _buildAvailableDeliveries(context, state),
          const SizedBox(height: 16),
          
          // Recent Activity
          _buildRecentActivity(context, state),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (state.driverStatus) {
      case DriverStatus.offline:
        statusColor = Colors.grey;
        statusText = 'Offline';
        statusIcon = Icons.power_settings_new;
        break;
      case DriverStatus.online:
        statusColor = Colors.green;
        statusText = 'Online & Available';
        statusIcon = Icons.check_circle;
        break;
      case DriverStatus.busy:
        statusColor = Colors.orange;
        statusText = 'Busy - On Delivery';
        statusIcon = Icons.local_shipping;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Status',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (state.driverStatus == DriverStatus.online)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Summary - ${dateFormat.format(DateTime.now())}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Deliveries',
                state.todayStats.deliveryCount.toString(),
                Icons.delivery_dining,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                'Earnings',
                '\$${state.todayStats.earnings.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Hours',
                '${(state.todayStats.onlineMinutes / 60).toStringAsFixed(1)}h',
                Icons.access_time,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                'Rating',
                state.todayStats.averageRating.toStringAsFixed(1),
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDeliveries(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Deliveries',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                context.push('/deliveries');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.availableDeliveries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No available deliveries',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else
          ...state.availableDeliveries.take(3).map(
            (delivery) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Order #${delivery.orderNumber}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${delivery.total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            delivery.deliveryAddress,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${delivery.distance.toStringAsFixed(1)} km',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/delivery/${delivery.id}');
                      },
                      child: const Text('Accept Delivery'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Active Deliveries',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (state.recentDeliveries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No active deliveries',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          )
        else
          ...state.recentDeliveries.take(5).map(
            (delivery) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () {
                  // Navigate to delivery details
                  context.go('/delivery/${delivery.id}');
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(delivery.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getStatusIcon(delivery.status),
                    color: _getStatusColor(delivery.status),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Order #${delivery.orderNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.customerName,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      _getStatusText(delivery.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(delivery.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  '\$${delivery.total.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.readyForPickup:
        return Colors.orange;
      case DeliveryStatus.accepted:
        return Colors.blue;
      case DeliveryStatus.pickedUp:
        return Colors.purple;
      case DeliveryStatus.inTransit:
        return Colors.green;
      case DeliveryStatus.delivered:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.readyForPickup:
        return Icons.restaurant;
      case DeliveryStatus.accepted:
        return Icons.check_circle;
      case DeliveryStatus.pickedUp:
        return Icons.local_shipping;
      case DeliveryStatus.inTransit:
        return Icons.directions_car;
      case DeliveryStatus.delivered:
        return Icons.check_circle;
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.readyForPickup:
        return 'Ready for pickup';
      case DeliveryStatus.accepted:
        return 'Accepted';
      case DeliveryStatus.pickedUp:
        return 'Picked up';
      case DeliveryStatus.inTransit:
        return 'In transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      default:
        return 'Pending';
    }
  }
} 
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardBloc>().add(const DashboardRefreshEvent());
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading dashboard...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card with Status
          _buildWelcomeCard(context, state),
          
          const SizedBox(height: 20),
          
          // Quick Stats Grid
          _buildQuickStatsGrid(context, state),
          
          const SizedBox(height: 24),
          
          // Available Deliveries Section
          _buildAvailableDeliveriesSection(context, state),
          
          const SizedBox(height: 24),
          
          // Active Deliveries Section
          _buildActiveDeliveriesSection(context, state),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);
    
    String statusText;
    IconData statusIcon;
    Color gradientStart;
    Color gradientEnd;
    
    switch (state.driverStatus) {
      case DriverStatus.offline:
        statusText = 'Offline';
        statusIcon = Icons.power_settings_new;
        gradientStart = Colors.grey.shade600;
        gradientEnd = Colors.grey.shade800;
        break;
      case DriverStatus.online:
        statusText = 'Online & Available';
        statusIcon = Icons.check_circle;
        gradientStart = theme.colorScheme.primary;
        gradientEnd = theme.colorScheme.secondary;
        break;
      case DriverStatus.busy:
        statusText = 'Busy - On Delivery';
        statusIcon = Icons.local_shipping;
        gradientStart = Colors.orange.shade600;
        gradientEnd = Colors.orange.shade800;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Today\'s Summary - ${dateFormat.format(DateTime.now())}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              context,
              'Deliveries',
              state.todayStats.deliveryCount.toString(),
              Icons.delivery_dining,
              Colors.blue,
            ),
            _buildStatCard(
              context,
              'Earnings',
              '\$${state.todayStats.earnings.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildStatCard(
              context,
              'Hours',
              '${(state.todayStats.onlineMinutes / 60).toStringAsFixed(1)}h',
              Icons.access_time,
              Colors.orange,
            ),
            _buildStatCard(
              context,
              'Rating',
              state.todayStats.averageRating.toStringAsFixed(1),
              Icons.star,
              theme.colorScheme.primary,
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDeliveriesSection(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Available Deliveries',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (state.availableDeliveries.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.push('/deliveries');
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.availableDeliveries.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.delivery_dining,
            title: 'No Available Deliveries',
            message: 'Check back later for new delivery opportunities',
          )
        else
          ...state.availableDeliveries.take(3).map(
            (delivery) => _buildDeliveryCard(context, delivery, isAvailable: true),
          ),
      ],
    );
  }

  Widget _buildActiveDeliveriesSection(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'My Active Deliveries',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.recentDeliveries.isEmpty)
          _buildEmptyState(
            context,
            icon: Icons.local_shipping,
            title: 'No Active Deliveries',
            message: 'You don\'t have any active deliveries at the moment',
          )
        else
          ...state.recentDeliveries.take(5).map(
            (delivery) => _buildDeliveryCard(context, delivery, isAvailable: false),
          ),
      ],
    );
  }

  Widget _buildDeliveryCard(BuildContext context, dynamic delivery, {required bool isAvailable}) {
    final theme = Theme.of(context);
    final orderNumber = delivery.orderNumber ?? delivery.id.substring(0, 7);
    final statusColor = _getStatusColor(delivery.status);
    final statusIcon = _getStatusIcon(delivery.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      statusIcon,
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
                          'Order #$orderNumber',
                          style: TextStyle(
                            fontSize: theme.textTheme.titleMedium?.fontSize ?? 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                delivery.customerName ?? 'Customer',
                                style: TextStyle(
                                  fontSize: theme.textTheme.bodySmall?.fontSize ?? 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${delivery.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: theme.textTheme.titleMedium?.fontSize ?? 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
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
                            _getStatusText(delivery.status),
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
                ],
              ),
              const SizedBox(height: 12),
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
                      delivery.deliveryAddress ?? 'Address not available',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (delivery.distance != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${delivery.distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: theme.textTheme.bodySmall?.fontSize ?? 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isAvailable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/delivery/${delivery.id}');
                    },
                    child: const Text('Accept Delivery'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
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
          ],
        ),
      ),
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

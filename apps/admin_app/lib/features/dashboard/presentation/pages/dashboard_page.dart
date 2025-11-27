
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/admin_layout.dart';
import '../../data/models/dashboard_overview_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return BlocProvider(
      create: (context) => GetIt.instance<DashboardBloc>()..add(const LoadDashboardStatistics()),
      child: AdminLayout(
        showAppBar: false,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isMobile ? 16 : 24),
              _HeroBanner(isMobile: isMobile),
              SizedBox(height: isMobile ? 16 : 24),
              BlocBuilder<DashboardBloc, DashboardState>(
                buildWhen: (previous, current) => previous != current,
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is DashboardError) {
                    return _DashboardErrorCard(
                      message: state.message,
                      onRetry: () => context.read<DashboardBloc>().add(const LoadDashboardStatistics()),
                    );
                  }

                  if (state is DashboardLoaded) {
                    return Column(
                      children: [
                        _OverviewMetricGrid(
                          overview: state.overview,
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              SizedBox(height: isMobile ? 20 : 24),
              _QuickActionsCard(isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isMobile;

  const _HeroBanner({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withOpacity(0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 24 : 32,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back! 👋',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 22 : 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitor orders, vendors, deliveries, and growth from a single command center.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    String subtitle = 'Syncing live metrics...';
                    if (state is DashboardLoaded) {
                      final formatter = DateFormat('MMM d, yyyy • h:mm a');
                      subtitle = 'Last synced ${formatter.format(state.fetchedAt)}';
                    }
                    return Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.dashboard_customize_rounded,
                size: isMobile ? 56 : 72,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewMetricGrid extends StatelessWidget {
  final DashboardOverview overview;

  const _OverviewMetricGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact();
    final currencyFormat = NumberFormat.compactCurrency(symbol: '\$');
    final growthRate = overview.customers.growthRate;
    final growthText = '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%';

    final metrics = [
      _MetricData(
        title: 'Orders Today',
        value: numberFormat.format(overview.orders.totals.today),
        subtitle: 'Week ${numberFormat.format(overview.orders.totals.week)} • Month ${numberFormat.format(overview.orders.totals.month)}',
        icon: Icons.shopping_bag_rounded,
        color: Colors.blue,
      ),
      _MetricData(
        title: 'Active Orders',
        value: numberFormat.format(overview.orders.active),
        subtitle: 'Pending deliveries: ${overview.orders.pendingDeliveries}',
        icon: Icons.local_shipping_rounded,
        color: Colors.orange,
      ),
      _MetricData(
        title: 'Revenue Today',
        value: currencyFormat.format(overview.revenue.today),
        subtitle: 'Week ${currencyFormat.format(overview.revenue.week)} • Month ${currencyFormat.format(overview.revenue.month)}',
        icon: Icons.attach_money_rounded,
        color: Colors.green,
      ),
      _MetricData(
        title: 'Total Revenue',
        value: currencyFormat.format(overview.revenue.total),
        subtitle: 'All-time gross sales',
        icon: Icons.trending_up_rounded,
        color: Colors.purple,
      ),
      _MetricData(
        title: 'Vendors Active',
        value: '${overview.vendors.active}/${overview.vendors.total}',
        subtitle: 'Avg rating ${overview.vendors.averageRating.toStringAsFixed(1)} ★',
        icon: Icons.store_rounded,
        color: Colors.teal,
      ),
      _MetricData(
        title: 'Customer Base',
        value: numberFormat.format(overview.customers.totalCustomers),
        subtitle: 'Growth $growthText',
        icon: Icons.people_alt_rounded,
        color: Colors.indigo,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200
            ? 4
            : width > 900
                ? 3
                : width > 600
                    ? 2
                    : 1;
        final spacing = width < 600 ? 8.0 : 16.0;
        final aspectRatio = crossAxisCount == 1 ? 3.8 : 3.2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) => _DashboardMetricCard(config: metrics[index]),
        );
      },
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final bool isMobile;

  const _QuickActionsCard({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flash_on_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Navigate to critical management panels instantly.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 16 : 20),
            _QuickActionsGrid(isMobile: isMobile),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final bool isMobile;

  const _QuickActionsGrid({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final spacing = isMobile ? 12.0 : 16.0;

    if (isMobile) {
      return Column(
        children: [
          _QuickActionButton(
            icon: Icons.people_alt_rounded,
            label: 'Manage Users',
            color: Colors.blue,
            onPressed: () => context.go('/users'),
            isFullWidth: true,
          ),
          SizedBox(height: spacing),
          _QuickActionButton(
            icon: Icons.store_mall_directory_rounded,
            label: 'Manage Shops',
            color: Colors.green,
            onPressed: () => context.go('/shops'),
            isFullWidth: true,
          ),
          SizedBox(height: spacing),
          _QuickActionButton(
            icon: Icons.local_mall_rounded,
            label: 'Orders Board',
            color: Colors.orange,
            onPressed: () => context.go('/orders'),
            isFullWidth: true,
          ),
          SizedBox(height: spacing),
          _QuickActionButton(
            icon: Icons.analytics_rounded,
            label: 'Analytics',
            color: Colors.purple,
            onPressed: () => context.go('/analytics'),
            isFullWidth: true,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.people_alt_rounded,
            label: 'Manage Users',
            color: Colors.blue,
            onPressed: () => context.go('/users'),
            isFullWidth: true,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.store_mall_directory_rounded,
            label: 'Manage Shops',
            color: Colors.green,
            onPressed: () => context.go('/shops'),
            isFullWidth: true,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.local_mall_rounded,
            label: 'Orders Board',
            color: Colors.orange,
            onPressed: () => context.go('/orders'),
            isFullWidth: true,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.analytics_rounded,
            label: 'Analytics',
            color: Colors.purple,
            onPressed: () => context.go('/analytics'),
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final _MetricData config;

  const _DashboardMetricCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config.icon, color: config.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: config.color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.title,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (config.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      config.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load dashboard metrics',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isFullWidth;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 800;
    final isVerySmall = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmall ? 12 : (isMobile ? 16 : 20),
              vertical: isMobile ? 14 : 16,
            ),
            child: Row(
              mainAxisAlignment: isFullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

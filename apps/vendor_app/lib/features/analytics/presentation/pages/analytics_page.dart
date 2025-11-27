import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/analytics_bloc.dart';
import '../widgets/real_time_metric_card.dart';
import '../widgets/real_time_order_status_widget.dart';
import '../widgets/real_time_sales_widget.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Week';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'Last 3 Months', 'This Year'];
  AnalyticsBloc? _analyticsBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load analytics when page initializes
    _analyticsBloc = context.read<AnalyticsBloc>();
    _analyticsBloc?.add(LoadAnalytics());
  }

  @override
  void dispose() {
    // Stop real-time updates when leaving the page
    if (mounted && _analyticsBloc != null) {
      _analyticsBloc!.add(StopRealTimeUpdates());
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          // Period Selector
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedPeriod,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              onSelected: (value) {
                setState(() {
                  _selectedPeriod = value;
                });
                context.read<AnalyticsBloc>().add(LoadAnalytics());
              },
              itemBuilder: (context) => _periods
                  .map((period) => PopupMenuItem(
                        value: period,
                        child: Row(
                          children: [
                            if (period == _selectedPeriod)
                              Icon(
                                Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(period),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<AnalyticsBloc>().add(LoadAnalytics());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Sales'),
            Tab(icon: Icon(Icons.assessment), text: 'Performance'),
          ],
        ),
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading analytics...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is AnalyticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AnalyticsBloc>().add(LoadAnalytics());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is AnalyticsLoaded || state is MetricUpdating) {
            final analyticsData = state is AnalyticsLoaded 
                ? state.analyticsData 
                : (state as MetricUpdating).analyticsData;
            final lastUpdated = state is AnalyticsLoaded 
                ? state.lastUpdated 
                : (state as MetricUpdating).lastUpdated;
            final updatingMetric = state is MetricUpdating ? state.updatingMetric : null;
                
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(analyticsData, lastUpdated, updatingMetric),
                _buildSalesTab(analyticsData, lastUpdated, updatingMetric),
                _buildPerformanceTab(analyticsData, lastUpdated, updatingMetric),
              ],
            );
          }

          return const Center(
            child: Text('No analytics data available'),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> data, DateTime lastUpdated, String? updatingMetric) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AnalyticsBloc>().add(LoadAnalytics());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Header Card
            _buildSummaryHeaderCard(context, lastUpdated),
            
            const SizedBox(height: 24),
            
            // Key Metrics Rows
            Text(
              'Key Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            RealTimeMetricCard(
              title: 'Total Orders',
              value: data['todayOrders']?.toString() ?? '0',
              icon: Icons.receipt_long,
              color: Colors.blue,
              change: '',
              isPositive: true,
              metricType: 'orders',
              isUpdating: updatingMetric == 'orders',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('orders'));
              },
            ),
            
            const SizedBox(height: 4),
            
            RealTimeMetricCard(
              title: 'Revenue',
              value: '\$${(data['todayRevenue'] ?? 0.0).toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.green,
              change: '',
              isPositive: true,
              metricType: 'revenue',
              isUpdating: updatingMetric == 'revenue',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('revenue'));
              },
            ),
            
            const SizedBox(height: 4),
            
            RealTimeMetricCard(
              title: 'Avg Order Value',
              value: '\$${(data['averageOrderValue'] ?? 0.0).toStringAsFixed(2)}',
              icon: Icons.trending_up,
              color: Colors.purple,
              change: '',
              isPositive: true,
              metricType: 'revenue',
              isUpdating: updatingMetric == 'revenue',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('revenue'));
              },
            ),
            
            const SizedBox(height: 4),
            
            RealTimeMetricCard(
              title: 'Rating',
              value: (data['rating'] ?? 0.0).toStringAsFixed(1),
              icon: Icons.star,
              color: Colors.orange,
              change: '${data['ratingCount'] ?? data['totalRatings'] ?? 0} reviews',
              isPositive: true,
              metricType: 'rating',
              isUpdating: updatingMetric == 'rating',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('rating'));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Order Status
            Text(
              'Order Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            RealTimeOrderStatusWidget(
              data: data,
              isUpdating: updatingMetric == 'orders',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('orders'));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Menu Statistics
            Text(
              'Menu Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            RealTimeMetricCard(
              title: 'Active Items',
              value: data['activeMenuItems']?.toString() ?? '0',
              icon: Icons.restaurant_menu,
              color: Colors.teal,
              change: '',
              isPositive: true,
              metricType: 'menu',
              isUpdating: updatingMetric == 'menu',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('menu'));
              },
            ),
            
            const SizedBox(height: 4),
            
            RealTimeMetricCard(
              title: 'Out of Stock',
              value: data['outOfStockItems']?.toString() ?? '0',
              icon: Icons.warning,
              color: Colors.red,
              change: '',
              isPositive: false,
              metricType: 'menu',
              isUpdating: updatingMetric == 'menu',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('menu'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeaderCard(BuildContext context, DateTime lastUpdated) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Period: $_selectedPeriod',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab(Map<String, dynamic> data, DateTime lastUpdated, String? updatingMetric) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AnalyticsBloc>().add(LoadAnalytics());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sales Summary Cards
            RealTimeMetricCard(
              title: 'Total Revenue',
              value: '\$${(data['totalRevenue'] ?? data['todayRevenue'] ?? 0.0).toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.green,
              change: '',
              isPositive: true,
              metricType: 'revenue',
              isUpdating: updatingMetric == 'revenue',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('revenue'));
              },
            ),
            
            const SizedBox(height: 4),
            
            RealTimeMetricCard(
              title: 'Total Orders',
              value: '${data['totalOrders'] ?? data['todayOrders'] ?? 0}',
              icon: Icons.receipt_long,
              color: Colors.blue,
              change: '',
              isPositive: true,
              metricType: 'orders',
              isUpdating: updatingMetric == 'orders',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('orders'));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Revenue Chart Section
            _buildSectionHeader(
              context,
              icon: Icons.trending_up,
              title: 'Revenue Trends',
            ),
            const SizedBox(height: 16),
            
            _buildRevenueTrendsChart(context, data),
            
            const SizedBox(height: 24),
            
            // Sales Summary by Period
            _buildSectionHeader(
              context,
              icon: Icons.analytics,
              title: 'Sales Summary',
            ),
            const SizedBox(height: 16),
            
            RealTimeSalesWidget(
              data: data,
              isUpdating: updatingMetric == 'revenue',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('revenue'));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Top Performing Items
            _buildSectionHeader(
              context,
              icon: Icons.restaurant_menu,
              title: 'Top Performing Items',
            ),
            const SizedBox(height: 16),
            
            _buildTopProductsList(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab(Map<String, dynamic> data, DateTime lastUpdated, String? updatingMetric) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AnalyticsBloc>().add(LoadAnalytics());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Metrics Header
            _buildSectionHeader(
              context,
              icon: Icons.speed,
              title: 'Performance Metrics',
            ),
            const SizedBox(height: 16),
            
            RealTimeMetricCard(
              title: 'Customer Rating',
              value: '${(data['rating'] ?? 0.0).toStringAsFixed(1)}/5.0',
              icon: Icons.star,
              color: Colors.orange,
              change: '${data['ratingCount'] ?? 0} reviews',
              isPositive: true,
              metricType: 'rating',
              isUpdating: updatingMetric == 'rating',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('rating'));
              },
            ),
            
            const SizedBox(height: 4),
            
            RealTimeMetricCard(
              title: 'Avg Prep Time',
              value: data['avgPrepTimeMinutes'] != null 
                  ? '${data['avgPrepTimeMinutes']} min'
                  : 'N/A',
              icon: Icons.timer,
              color: Colors.blue,
              change: data['avgPrepTimeMinutes'] != null ? 'Average time' : 'No data',
              isPositive: true,
              metricType: 'performance',
              isUpdating: false,
              onRefresh: () {},
            ),
            
            const SizedBox(height: 4),
            
            RealTimeMetricCard(
              title: 'Order Accuracy',
              value: data['orderAccuracy'] != null 
                  ? '${data['orderAccuracy']}%'
                  : 'N/A',
              icon: Icons.check_circle,
              color: Colors.green,
              change: data['orderAccuracy'] != null ? 'Success rate' : 'No data',
              isPositive: true,
              metricType: 'performance',
              isUpdating: false,
              onRefresh: () {},
            ),
            
            const SizedBox(height: 4),
            
            RealTimeMetricCard(
              title: 'Total Orders',
              value: '${data['totalOrders'] ?? 0}',
              icon: Icons.trending_up,
              color: Colors.purple,
              change: 'All time',
              isPositive: true,
              metricType: 'orders',
              isUpdating: updatingMetric == 'orders',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(const RefreshMetric('orders'));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Peak Hours Analysis
            _buildSectionHeader(
              context,
              icon: Icons.schedule,
              title: 'Peak Hours Analysis',
            ),
            const SizedBox(height: 16),
            
            _buildPeakHoursChart(context, data),
            
            const SizedBox(height: 24),
            
            // Business Insights
            _buildSectionHeader(
              context,
              icon: Icons.lightbulb_outline,
              title: 'Business Insights',
            ),
            const SizedBox(height: 16),
            
            _buildBusinessInsightsCard(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildChartPlaceholder(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Container(
        height: 220,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTrendsChart(BuildContext context, Map<String, dynamic> data) {
    final revenueTrend = data['revenueTrend'] as List<dynamic>? ?? [];
    
    if (revenueTrend.isEmpty) {
      return _buildChartPlaceholder(
        context,
        title: 'Revenue Chart',
        subtitle: 'No revenue data available yet',
        icon: Icons.bar_chart,
      );
    }

    // Calculate max revenue for scaling
    final maxRevenue = revenueTrend.map((e) => (e['revenue'] as num?)?.toDouble() ?? 0.0).fold(0.0, (a, b) => a > b ? a : b);
    final maxHeight = 120.0; // Reduced to leave room for labels

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 Days',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: maxHeight + 50, // Increased to accommodate labels
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: revenueTrend.asMap().entries.map((entry) {
                  final day = entry.value as Map<String, dynamic>;
                  final revenue = (day['revenue'] as num?)?.toDouble() ?? 0.0;
                  final date = day['date'] as String? ?? '';
                  final dayName = _getDayName(date);
                  final height = maxRevenue > 0 ? (revenue / maxRevenue) * maxHeight : 0.0;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: height > 0 ? height : 2,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dayName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '\$${revenue.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 8,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList(BuildContext context, Map<String, dynamic> data) {
    final topProducts = data['topProducts'] as List<dynamic>? ?? [];
    
    if (topProducts.isEmpty) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No product data available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Product analytics will appear here once you start receiving orders.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: topProducts.asMap().entries.map((entry) {
        final product = entry.value as Map<String, dynamic>;
        final rank = entry.key + 1;
        final productName = product['productName'] as String? ?? 'Unknown Product';
        final totalRevenue = (product['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        final orderCount = product['orderCount'] as int? ?? 0;
        final totalQuantity = (product['totalQuantity'] as num?)?.toInt() ?? 0;

        return Padding(
          padding: EdgeInsets.only(bottom: rank <= topProducts.length ? 4 : 0),
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.grey.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: rank <= 3
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$orderCount orders • $totalQuantity sold',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Revenue
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${totalRevenue.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        'Revenue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDayName(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      if (dateOnly == today) {
        return 'Today';
      } else if (dateOnly == today.subtract(const Duration(days: 1))) {
        return 'Yesterday';
      } else {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[date.weekday - 1];
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildPeakHoursChart(BuildContext context, Map<String, dynamic> data) {
    final peakHours = data['peakHours'] as List<dynamic>? ?? [];
    
    if (peakHours.isEmpty) {
      return _buildChartPlaceholder(
        context,
        title: 'Peak Hours Chart',
        subtitle: 'No order data available yet',
        icon: Icons.schedule,
      );
    }

    // Calculate max count for scaling
    final maxCount = peakHours.map((e) => (e['count'] as num?)?.toInt() ?? 0).fold(0, (a, b) => a > b ? a : b);
    final maxHeight = 100.0; // Reduced from 120

    // Find peak hour
    final peakHour = data['peakHour'] as int?;
    final peakHourCount = data['peakHourCount'] as int? ?? 0;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (peakHour != null && peakHourCount > 0) ...[
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Peak Hour: ${peakHour}:00 (${peakHourCount} orders)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: maxHeight + 35, // Reduced from 40
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: peakHours.map((hourData) {
                  final hour = (hourData['hour'] as num?)?.toInt() ?? 0;
                  final count = (hourData['count'] as num?)?.toInt() ?? 0;
                  final height = maxCount > 0 ? (count / maxCount) * maxHeight : 0.0;
                  final isPeak = peakHour != null && hour == peakHour;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1), // Reduced from 2
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: height > 0 ? height : 2,
                            decoration: BoxDecoration(
                              color: isPeak 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[400]!,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4), // Reduced from 6
                          Text(
                            '${hour.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 7, // Reduced from 8
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (count > 0)
                            Text(
                              '$count',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 6, // Reduced from 7
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBusinessInsightsCard(BuildContext context, Map<String, dynamic> data) {
    final insights = <Widget>[];
    
    // Insight 1: Prep time performance
    final avgPrepTime = data['avgPrepTimeMinutes'] as int?;
    if (avgPrepTime != null) {
      if (avgPrepTime > 30) {
        insights.add(_buildSuggestionItem(
          Icons.timer_off,
          'Improve Prep Time',
          'Your average prep time is ${avgPrepTime} minutes. Consider optimizing kitchen workflow.',
          Colors.orange,
        ));
        insights.add(const SizedBox(height: 16));
        insights.add(Divider(color: Colors.grey[200]));
        insights.add(const SizedBox(height: 16));
      } else if (avgPrepTime <= 20) {
        insights.add(_buildSuggestionItem(
          Icons.check_circle,
          'Excellent Prep Time',
          'Your average prep time of ${avgPrepTime} minutes is great! Keep it up.',
          Colors.green,
        ));
        insights.add(const SizedBox(height: 16));
        insights.add(Divider(color: Colors.grey[200]));
        insights.add(const SizedBox(height: 16));
      }
    }
    
    // Insight 2: Order accuracy
    final orderAccuracy = data['orderAccuracy'] as int?;
    if (orderAccuracy != null && orderAccuracy < 95) {
      insights.add(_buildSuggestionItem(
        Icons.warning,
        'Order Accuracy',
        'Your order accuracy is ${orderAccuracy}%. Focus on reducing errors.',
        Colors.red,
      ));
      insights.add(const SizedBox(height: 16));
      insights.add(Divider(color: Colors.grey[200]));
      insights.add(const SizedBox(height: 16));
    }
    
    // Insight 3: Peak hours
    final peakHour = data['peakHour'] as int?;
    if (peakHour != null) {
      insights.add(_buildSuggestionItem(
        Icons.access_time,
        'Peak Hours',
        'Your busiest time is ${peakHour}:00. Ensure adequate staffing during this period.',
        Colors.blue,
      ));
      insights.add(const SizedBox(height: 16));
      insights.add(Divider(color: Colors.grey[200]));
      insights.add(const SizedBox(height: 16));
    }
    
    // Insight 4: Revenue performance
    final todayRevenue = (data['todayRevenue'] as num?)?.toDouble() ?? 0.0;
    final weekRevenue = (data['weekRevenue'] as num?)?.toDouble() ?? 0.0;
    if (todayRevenue > 0 && weekRevenue > 0) {
      final dailyAvg = weekRevenue / 7;
      if (todayRevenue < dailyAvg * 0.7) {
        insights.add(_buildSuggestionItem(
          Icons.trending_down,
          'Low Sales Today',
          'Today\'s revenue is below average. Consider promotions or marketing.',
          Colors.orange,
        ));
      } else if (todayRevenue > dailyAvg * 1.3) {
        insights.add(_buildSuggestionItem(
          Icons.trending_up,
          'Great Sales Today',
          'Today\'s revenue is above average! Excellent performance.',
          Colors.green,
        ));
      }
    }
    
    // Default insights if no data
    if (insights.isEmpty) {
      insights.add(_buildSuggestionItem(
        Icons.restaurant_menu,
        'Get Started',
        'Start receiving orders to see personalized insights here.',
        Colors.blue,
      ));
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: insights,
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

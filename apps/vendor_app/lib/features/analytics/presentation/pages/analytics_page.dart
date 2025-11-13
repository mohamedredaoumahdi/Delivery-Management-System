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
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'Last 3 Months'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load analytics when page initializes
    context.read<AnalyticsBloc>().add(LoadAnalytics());
  }

  @override
  void dispose() {
    // Stop real-time updates when leaving the page
    context.read<AnalyticsBloc>().add(StopRealTimeUpdates());
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AnalyticsBloc>().add(LoadAnalytics());
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => _periods
                .map((period) => PopupMenuItem(
                      value: period,
                      child: Text(period),
                    ))
                .toList(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Performance'),
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
                  ElevatedButton(
                    onPressed: () {
                      context.read<AnalyticsBloc>().add(LoadAnalytics());
                    },
                    child: const Text('Retry'),
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
            // Header Card
            Container(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                  'Updated: ${_formatTime(lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                ),
            ),
            
            const SizedBox(height: 24),
            
            // Real-time Key Metrics
            Row(
              children: [
                Expanded(
                  child: RealTimeMetricCard(
                    title: 'Total Orders',
                    value: data['todayOrders']?.toString() ?? '0',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    change: '+12%',
                    isPositive: true,
                    metricType: 'orders',
                    isUpdating: updatingMetric == 'orders',
                    onRefresh: () {
                      context.read<AnalyticsBloc>().add(RefreshMetric('orders'));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RealTimeMetricCard(
                    title: 'Revenue',
                    value: '\$${(data['todayRevenue'] ?? 0.0).toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    change: '+8%',
                    isPositive: true,
                    metricType: 'revenue',
                    isUpdating: updatingMetric == 'revenue',
                    onRefresh: () {
                      context.read<AnalyticsBloc>().add(RefreshMetric('revenue'));
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: RealTimeMetricCard(
                    title: 'Avg Order Value',
                    value: '\$${(data['averageOrderValue'] ?? 0.0).toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                    change: '+5%',
                    isPositive: true,
                    metricType: 'revenue',
                    isUpdating: updatingMetric == 'revenue',
                    onRefresh: () {
                      context.read<AnalyticsBloc>().add(RefreshMetric('revenue'));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RealTimeMetricCard(
                    title: 'Rating',
                    value: (data['rating'] ?? 0.0).toStringAsFixed(1),
                    icon: Icons.star,
                    color: Colors.orange,
                    change: '↗',
                    isPositive: true,
                    metricType: 'rating',
                    isUpdating: updatingMetric == 'rating',
                    onRefresh: () {
                      context.read<AnalyticsBloc>().add(RefreshMetric('rating'));
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Real-time Order Status Overview
            RealTimeOrderStatusWidget(
              data: data,
              isUpdating: updatingMetric == 'orders',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(RefreshMetric('orders'));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Quick Stats
            Text(
              'Menu Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: RealTimeMetricCard(
                    title: 'Active Menu Items',
                    value: data['activeMenuItems']?.toString() ?? '0',
                    icon: Icons.restaurant_menu,
                    color: Colors.teal,
                    change: '',
                    isPositive: true,
                    metricType: 'menu',
                    isUpdating: updatingMetric == 'menu',
                    showMiniCard: true,
                    onRefresh: () {
                      context.read<AnalyticsBloc>().add(RefreshMetric('menu'));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RealTimeMetricCard(
                    title: 'Out of Stock',
                    value: data['outOfStockItems']?.toString() ?? '0',
                    icon: Icons.warning,
                    color: Colors.red,
                    change: '',
                    isPositive: false,
                    metricType: 'menu',
                    isUpdating: updatingMetric == 'menu',
                    showMiniCard: true,
                    onRefresh: () {
                      context.read<AnalyticsBloc>().add(RefreshMetric('menu'));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
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
            // Revenue Chart Placeholder
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
            Text(
              'Revenue Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[50]!,
                      Colors.grey[100]!,
                    ],
                  ),
                ),
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
                      Icons.bar_chart,
                      size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Revenue Chart',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visual charts coming soon!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Real-time Sales Summary
            RealTimeSalesWidget(
              data: data,
              isUpdating: updatingMetric == 'revenue',
              onRefresh: () {
                context.read<AnalyticsBloc>().add(RefreshMetric('revenue'));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Top Performing Items
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
            Text(
              'Top Performing Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                      Icons.restaurant_menu,
                      size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Product Analytics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Detailed product performance metrics will be available soon.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.speed,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
            Text(
              'Performance Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: RealTimeMetricCard(
                    title: 'Customer Rating',
                    value: '${(data['rating'] ?? 0.0).toStringAsFixed(1)}/5.0',
                    icon: Icons.star,
                    color: Colors.orange,
                    change: '${data['ratingCount'] ?? 0} reviews',
                    isPositive: true,
                    metricType: 'rating',
                    isUpdating: updatingMetric == 'rating',
                    showMiniCard: true,
                    onRefresh: () {
                      context.read<AnalyticsBloc>().add(RefreshMetric('rating'));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceCard(
                    'Avg Prep Time',
                    'Not available',
                    Icons.timer,
                    Colors.blue,
                    'Coming soon',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    'Order Accuracy',
                    'Not available',
                    Icons.check_circle,
                    Colors.green,
                    'Coming soon',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RealTimeMetricCard(
                    title: 'Total Orders',
                    value: '${data['totalOrders'] ?? 0}',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                    change: 'All time',
                    isPositive: true,
                    metricType: 'orders',
                    isUpdating: updatingMetric == 'orders',
                    showMiniCard: true,
                    onRefresh: () {
                      context.read<AnalyticsBloc>().add(RefreshMetric('orders'));
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Peak Hours Chart Placeholder
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
            Text(
              'Peak Hours Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[50]!,
                      Colors.grey[100]!,
                    ],
                  ),
                ),
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
                      Icons.schedule,
                      size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Peak Hours Chart',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Peak hours analysis coming soon!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Business Insights
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
            Text(
              'Business Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSuggestionItem(
                      Icons.restaurant_menu,
                      'Add Menu Items',
                      'Start by adding items to your menu to attract customers',
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    _buildSuggestionItem(
                      Icons.schedule,
                      'Set Operating Hours',
                      'Make sure your operating hours are clearly defined',
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    _buildSuggestionItem(
                      Icons.delivery_dining,
                      'Enable Delivery',
                      'Consider offering delivery to reach more customers',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
} 
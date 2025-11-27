import 'package:flutter/material.dart';

class RealTimeSalesWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isUpdating;
  final VoidCallback onRefresh;

  const RealTimeSalesWidget({
    super.key,
    required this.data,
    required this.isUpdating,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = data.isNotEmpty && 
        (data['todayRevenue'] != null || data['totalRevenue'] != null);
    
    if (!hasData) {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No sales data available yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sales data will appear here once you start receiving orders.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSalesCard(
          context,
          icon: Icons.today,
          title: 'Today',
          revenue: (data['todayRevenue'] ?? 0.0).toDouble(),
          orders: data['todayOrders'] ?? 0,
          color: Colors.blue,
        ),
        const SizedBox(height: 4),
        _buildSalesCard(
          context,
          icon: Icons.calendar_view_week,
          title: 'This Week',
          revenue: (data['weekRevenue'] ?? 0.0).toDouble(),
          orders: data['weekOrders'] ?? 0,
          color: Colors.green,
        ),
        const SizedBox(height: 4),
        _buildSalesCard(
          context,
          icon: Icons.calendar_month,
          title: 'This Month',
          revenue: (data['monthRevenue'] ?? 0.0).toDouble(),
          orders: data['monthOrders'] ?? 0,
          color: Colors.purple,
        ),
        const SizedBox(height: 4),
        _buildSalesCard(
          context,
          icon: Icons.all_inclusive,
          title: 'All Time',
          revenue: (data['totalRevenue'] ?? 0.0).toDouble(),
          orders: data['totalOrders'] ?? 0,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSalesCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double revenue,
    required int orders,
    required Color color,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${revenue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$orders orders',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

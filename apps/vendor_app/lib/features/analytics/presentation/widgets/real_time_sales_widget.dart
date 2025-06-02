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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sales Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isUpdating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isUpdating ? 0.6 : 1.0,
              child: _buildSalesContent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesContent(BuildContext context) {
    final hasData = data.isNotEmpty && 
        (data['todayRevenue'] != null || data['totalRevenue'] != null);
    
    if (!hasData) {
      return Column(
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
      );
    }

    return Column(
      children: [
        _buildSalesRow(
          'Today', 
          (data['todayRevenue'] ?? 0.0).toDouble(), 
          data['todayOrders'] ?? 0,
        ),
        const Divider(),
        _buildSalesRow(
          'This Week', 
          (data['weekRevenue'] ?? 0.0).toDouble(), 
          data['weekOrders'] ?? 0,
        ),
        const Divider(),
        _buildSalesRow(
          'This Month', 
          (data['monthRevenue'] ?? 0.0).toDouble(), 
          data['monthOrders'] ?? 0,
        ),
        const Divider(),
        _buildSalesRow(
          'All Time', 
          (data['totalRevenue'] ?? 0.0).toDouble(), 
          data['totalOrders'] ?? 0,
        ),
      ],
    );
  }

  Widget _buildSalesRow(String period, double revenue, int orders) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              period,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '\$${revenue.toStringAsFixed(2)}',
                  key: ValueKey('$period-revenue-$revenue'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '$orders orders',
                  key: ValueKey('$period-orders-$orders'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 
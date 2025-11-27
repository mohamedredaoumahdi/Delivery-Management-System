import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../common/widgets/admin_layout.dart';
import '../../../dashboard/data/dashboard_service.dart';
import '../../../dashboard/data/models/dashboard_overview_model.dart';

class DeliveryAnalyticsPage extends StatefulWidget {
  const DeliveryAnalyticsPage({super.key});

  @override
  State<DeliveryAnalyticsPage> createState() => _DeliveryAnalyticsPageState();
}

class _DeliveryAnalyticsPageState extends State<DeliveryAnalyticsPage> {
  final DashboardService _dashboardService = GetIt.instance<DashboardService>();
  bool _isLoading = true;
  String? _error;
  DashboardOverview? _overview;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadAnalytics(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAnalytics({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final overview = await _dashboardService.getStatistics();
      if (mounted) {
        setState(() {
          _overview = overview;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return AdminLayout(
      showAppBar: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isMobile ? 16 : 24),
            _HeaderSection(isMobile: isMobile, onRefresh: _loadAnalytics),
            SizedBox(height: isMobile ? 16 : 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorCard(
                message: _error!,
                onRetry: _loadAnalytics,
              )
            else if (_overview == null)
              _EmptyState()
            else ...[
              _DeliverySummaryCard(
                delivery: _overview!.delivery,
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _AgentStatusCard(
                delivery: _overview!.delivery,
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _DeliveryPerformanceCard(
                delivery: _overview!.delivery,
                isMobile: isMobile,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onRefresh;

  const _HeaderSection({
    required this.isMobile,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue,
                    Colors.blue.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Delivery network performance and insights',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                        fontSize: isMobile ? 12 : 14,
                      ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

class _DeliverySummaryCard extends StatelessWidget {
  final DeliveryInsights delivery;
  final bool isMobile;

  const _DeliverySummaryCard({
    required this.delivery,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Network Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.people,
                    label: 'Total Agents',
                    value: delivery.totalAgents.toString(),
                    color: Colors.blue,
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 20),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.check_circle,
                    label: 'Active Agents',
                    value: delivery.activeAgents.toString(),
                    color: Colors.green,
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 20),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.wifi,
                    label: 'Online',
                    value: delivery.onlineAgents.toString(),
                    color: Colors.teal,
                    isMobile: isMobile,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.delivery_dining,
                    label: 'Completed Today',
                    value: delivery.completedToday.toString(),
                    color: Colors.purple,
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 20),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.timer,
                    label: 'Avg Delivery Time',
                    value: '${delivery.averageDeliveryTimeMinutes} min',
                    color: Colors.orange,
                    isMobile: isMobile,
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

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isMobile;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: isMobile ? 20 : 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentStatusCard extends StatelessWidget {
  final DeliveryInsights delivery;
  final bool isMobile;

  const _AgentStatusCard({
    required this.delivery,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agent Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 20),
            if (delivery.activeAgents == 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No active delivery agents',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              )
            else ...[
              if (delivery.onlineAgents > 0)
                _AgentStatusItem(
                  agentName: 'Online Agents',
                  status: '${delivery.onlineAgents} agent${delivery.onlineAgents > 1 ? 's' : ''} available',
                  isOnline: true,
                  isMobile: isMobile,
                ),
              if (delivery.onlineAgents > 0 && delivery.offlineAgents > 0)
                const SizedBox(height: 12),
              if (delivery.offlineAgents > 0)
                _AgentStatusItem(
                  agentName: 'Offline Agents',
                  status: '${delivery.offlineAgents} agent${delivery.offlineAgents > 1 ? 's' : ''} unavailable',
                  isOnline: false,
                  isMobile: isMobile,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgentStatusItem extends StatelessWidget {
  final String agentName;
  final String status;
  final bool isOnline;
  final bool isMobile;

  const _AgentStatusItem({
    required this.agentName,
    required this.status,
    required this.isOnline,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agentName,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPerformanceCard extends StatelessWidget {
  final DeliveryInsights delivery;
  final bool isMobile;

  const _DeliveryPerformanceCard({
    required this.delivery,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onlinePercentage = delivery.totalAgents > 0 
        ? (delivery.onlineAgents / delivery.totalAgents) 
        : 0.0;
    final activePercentage = delivery.totalAgents > 0 
        ? (delivery.activeAgents / delivery.totalAgents) 
        : 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Performance',
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 20),
            _PerformanceMetricRow(
              label: 'Network Availability',
              value: '${(onlinePercentage * 100).toStringAsFixed(1)}%',
              progress: onlinePercentage,
              color: Colors.green,
              isMobile: isMobile,
            ),
            const SizedBox(height: 16),
            _PerformanceMetricRow(
              label: 'Active Agent Rate',
              value: '${(activePercentage * 100).toStringAsFixed(1)}%',
              progress: activePercentage,
              color: Colors.blue,
              isMobile: isMobile,
            ),
            const SizedBox(height: 16),
            _PerformanceMetricRow(
              label: 'Average Delivery Time',
              value: '${delivery.averageDeliveryTimeMinutes} min',
              progress: delivery.averageDeliveryTimeMinutes > 0 
                  ? (60.0 / delivery.averageDeliveryTimeMinutes).clamp(0.0, 1.0)
                  : 0.0,
              color: Colors.orange,
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PerformanceStatChip(
                    label: 'Deliveries Today',
                    value: delivery.completedToday.toString(),
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PerformanceStatChip(
                    label: 'Offline Agents',
                    value: delivery.offlineAgents.toString(),
                    color: Colors.grey,
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

class _PerformanceMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  final bool isMobile;

  const _PerformanceMetricRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PerformanceStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No delivery data available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Delivery analytics will appear here once delivery agents are active',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading analytics',
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


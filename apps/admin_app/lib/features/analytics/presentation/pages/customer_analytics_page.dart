import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../common/widgets/admin_layout.dart';
import '../../data/analytics_service.dart';

class CustomerAnalyticsPage extends StatefulWidget {
  const CustomerAnalyticsPage({super.key});

  @override
  State<CustomerAnalyticsPage> createState() => _CustomerAnalyticsPageState();
}

class _CustomerAnalyticsPageState extends State<CustomerAnalyticsPage> {
  final AnalyticsService _analyticsService = GetIt.instance<AnalyticsService>();
  bool _isLoading = true;
  List<dynamic>? _userAnalytics;
  String? _error;
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
      final analytics = await _analyticsService.getUserAnalytics();
      if (mounted) {
        setState(() {
          _userAnalytics = analytics;
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
            else if (_userAnalytics == null || _userAnalytics!.isEmpty)
              _EmptyState()
            else ...[
              _CustomerSummaryCard(
                userAnalytics: _userAnalytics!,
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 16 : 24),
              _CustomerDistributionCard(
                userAnalytics: _userAnalytics!,
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
                    Colors.purple,
                    Colors.purple.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer growth and demographics',
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

class _CustomerSummaryCard extends StatelessWidget {
  final List<dynamic> userAnalytics;
  final bool isMobile;

  const _CustomerSummaryCard({
    required this.userAnalytics,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final customerData = userAnalytics.firstWhere(
      (item) => item['role'] == 'CUSTOMER',
      orElse: () => {'_count': 0},
    );
    final countData = customerData['_count'];
    int totalCustomers;
    if (countData is Map<String, dynamic>) {
      totalCustomers = (countData['_all'] as num?)?.toInt() ?? 0;
    } else if (countData is num) {
      totalCustomers = countData.toInt();
    } else {
      totalCustomers = 0;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Summary',
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
                    label: 'Total Customers',
                    value: totalCustomers.toString(),
                    color: Colors.purple,
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 20),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.trending_up,
                    label: 'Growth Rate',
                    value: '+10.5%',
                    color: Colors.green,
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

class _CustomerDistributionCard extends StatelessWidget {
  final List<dynamic> userAnalytics;
  final bool isMobile;

  const _CustomerDistributionCard({
    required this.userAnalytics,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final totalUsers = userAnalytics.fold<int>(
      0,
      (sum, item) {
        final countData = item['_count'];
        int countValue;
        if (countData is Map<String, dynamic>) {
          countValue = (countData['_all'] as num?)?.toInt() ?? 0;
        } else if (countData is num) {
          countValue = countData.toInt();
        } else {
          countValue = 0;
        }
        return sum + countValue;
      },
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 20),
            ...userAnalytics.map<Widget>((item) {
              final role = item['role'] ?? 'Unknown';
              final countData = item['_count'];
              int count;
              if (countData is Map<String, dynamic>) {
                count = (countData['_all'] as num?)?.toInt() ?? 0;
              } else if (countData is num) {
                count = countData.toInt();
              } else {
                count = 0;
              }
              final percentage = totalUsers > 0 ? (count / totalUsers) : 0.0;

              Color roleColor;
              IconData roleIcon;
              switch (role) {
                case 'CUSTOMER':
                  roleColor = Colors.blue;
                  roleIcon = Icons.person;
                  break;
                case 'VENDOR':
                  roleColor = Colors.green;
                  roleIcon = Icons.store;
                  break;
                case 'DELIVERY':
                  roleColor = Colors.orange;
                  roleIcon = Icons.local_shipping;
                  break;
                case 'ADMIN':
                  roleColor = Colors.purple;
                  roleIcon = Icons.admin_panel_settings;
                  break;
                default:
                  roleColor = Colors.grey;
                  roleIcon = Icons.person_outline;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(roleIcon, color: roleColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: roleColor.withOpacity(0.1),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(roleColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: roleColor,
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
            }),
          ],
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
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No customer data available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Customer analytics will appear here once customers register',
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


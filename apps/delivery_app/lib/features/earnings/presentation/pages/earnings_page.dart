import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/models/earnings_data.dart' show EarningsData, DeliveryEarning, PaymentHistory;
import '../bloc/earnings_bloc.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'Last 3 Months'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<EarningsBloc>().add(const EarningsLoadEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<EarningsBloc>().add(const EarningsRefreshEvent());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'History'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: BlocBuilder<EarningsBloc, EarningsState>(
        builder: (context, state) {
          if (state is EarningsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EarningsError) {
            return _buildErrorView(context, state.message);
          }

          if (state is EarningsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, state.data),
                _buildHistoryTab(context, state.data),
                _buildAnalyticsTab(context, state.data),
              ],
            );
          }

          return const Center(child: Text('No earnings data available'));
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
              'Unable to load earnings',
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
                context.read<EarningsBloc>().add(const EarningsLoadEvent());
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, EarningsData data) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<EarningsBloc>().add(const EarningsRefreshEvent());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(context),
            const SizedBox(height: 16),

            // Total Earnings Card
            _buildTotalEarningsCard(context, data),
            const SizedBox(height: 16),

            // Quick Stats
            _buildQuickStats(context, data),
            const SizedBox(height: 16),

            // Today's Deliveries
            _buildTodaysDeliveries(context, data),
            const SizedBox(height: 16),

            // Earnings Breakdown
            _buildEarningsBreakdown(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<EarningsBloc>().add(const EarningsRefreshEvent());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment History Header
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
              children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment History',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Payments
            _buildPaymentHistory(context, data),
            const SizedBox(height: 20),

            // Weekly Summary
            _buildWeeklySummary(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(BuildContext context, EarningsData data) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<EarningsBloc>().add(const EarningsRefreshEvent());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Metrics
            _buildPerformanceMetrics(context, data),
            const SizedBox(height: 20),

            // Hourly Earnings Chart
            _buildHourlyEarningsChart(context, data),
            const SizedBox(height: 20),

            // Tips Analysis
            _buildTipsAnalysis(context, data),
            const SizedBox(height: 20),

            // Goals and Achievements
            _buildGoalsSection(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Period:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPeriod = newValue;
                      });
                      // Map UI period to backend period
                      String backendPeriod;
                      switch (_selectedPeriod) {
                        case 'Today':
                          backendPeriod = 'today';
                          break;
                        case 'This Week':
                          backendPeriod = 'week';
                          break;
                        case 'This Month':
                          backendPeriod = 'month';
                          break;
                        case 'Last 3 Months':
                          backendPeriod = '3months';
                          break;
                        default:
                          backendPeriod = 'today';
                      }
                      // Trigger data refresh for new period
                      context.read<EarningsBloc>().add(EarningsPeriodChangedEvent(backendPeriod));
                    }
                  },
                  items: _periods.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.primary,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
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
                      'Total Earnings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All Time',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '\$${data.totalEarnings.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.green.shade200,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '+\$${data.todayEarnings.toStringAsFixed(2)} today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
          children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Quick Stats',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 12),
        // Stats in two rows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 20,
            runSpacing: 12,
          children: [
              SizedBox(
                width: 150,
                child: _buildStatItem(
                context,
                'Deliveries',
                '${data.deliveryCount}',
                Icons.local_shipping,
                Colors.blue,
              ),
            ),
              SizedBox(
                width: 150,
                child: _buildStatItem(
                context,
                'Avg/Order',
                '\$${data.averagePerOrder.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
              SizedBox(
                width: 150,
                child: _buildStatItem(
                context,
                'Online Time',
                '${data.onlineHours}h ${data.onlineMinutes}m',
                Icons.access_time,
                Colors.orange,
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Row(
          children: [
            Container(
          width: 48,
          height: 48,
              decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
            size: 24,
              ),
            ),
        const SizedBox(width: 12),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      ],
    );
  }

  Widget _buildTodaysDeliveries(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
          children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Deliveries',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          ),
        ),
        const SizedBox(height: 16),
        if (data.recentDeliveries.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Deliveries Yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed deliveries will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: data.recentDeliveries.take(5).map((delivery) => 
            _buildDeliveryItem(context, delivery)
                ).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryItem(BuildContext context, DeliveryEarning delivery) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${delivery.orderNumber.length > 20 ? '${delivery.orderNumber.substring(0, 20)}...' : delivery.orderNumber}',
                  style: TextStyle(
                    fontSize: theme.textTheme.titleMedium?.fontSize ?? 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(delivery.completedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+\$${delivery.earnings.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${delivery.distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildEarningsBreakdown(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
          children: [
              Icon(
                Icons.pie_chart,
                size: 20,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Earnings Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
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
                _buildBreakdownItem('Base Pay', data.basePay, Colors.blue),
                const SizedBox(height: 8),
                _buildBreakdownItem('Tips', data.tips, Colors.green),
                const SizedBox(height: 8),
                _buildBreakdownItem('Bonuses', data.bonuses, Colors.purple),
                const SizedBox(height: 8),
                _buildBreakdownItem('Distance Bonus', data.distanceBonus, Colors.orange),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                _buildBreakdownItem('Total', data.totalEarnings, theme.colorScheme.primary, isTotal: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, double amount, Color color, {bool isTotal = false}) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isTotal ? Icons.account_balance_wallet : Icons.circle,
            color: color,
            size: isTotal ? 20 : 12,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? theme.colorScheme.primary : color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    if (data.paymentHistory.isEmpty) {
    return Card(
        elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
      ),
      child: Padding(
          padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Payment History',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your payment history will appear here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      );
    }

    return Card(
      elevation: 0,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: data.paymentHistory.map((payment) => _buildPaymentItem(context, payment)).toList(),
        ),
      ),
    );
  }

  Widget _buildPaymentItem(BuildContext context, PaymentHistory payment) {
    final theme = Theme.of(context);
    final isPaid = payment.status.toUpperCase() == 'PAID';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                    payment.description,
                        style: TextStyle(
                          fontSize: theme.textTheme.titleMedium?.fontSize ?? 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid 
                            ? Colors.green.withValues(alpha: 0.1) 
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        payment.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(payment.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
                Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildWeeklySummary(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
          children: [
              Icon(
                Icons.calendar_view_week_outlined,
                size: 20,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'This Week Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 20,
            runSpacing: 12,
              children: [
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'Deliveries',
                  '${data.weeklyDeliveries}',
                  Icons.local_shipping,
                  Colors.blue,
                ),
                ),
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'Earnings',
                  '\$${data.weeklyEarnings.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                ),
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'Hours',
                  '${data.weeklyHours}h',
                  Icons.access_time,
                  Colors.orange,
          ),
        ),
      ],
          ),
        ),
      ],
    );
  }


  Widget _buildPerformanceMetrics(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
          children: [
              Icon(
                Icons.trending_up_outlined,
                size: 20,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Performance Metrics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 20,
            runSpacing: 12,
          children: [
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'Acceptance Rate',
                '${data.acceptanceRate.toStringAsFixed(0)}%',
                  Icons.check_circle,
                Colors.green,
              ),
            ),
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'Customer Rating',
                '${data.customerRating.toStringAsFixed(1)}/5',
                  Icons.star,
                Colors.amber,
              ),
            ),
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'On-Time Rate',
                '${data.onTimeRate.toStringAsFixed(0)}%',
                  Icons.access_time,
                Colors.blue,
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyEarningsChart(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    // Group recent deliveries by day
    final Map<String, double> dailyEarnings = {};
    for (var delivery in data.recentDeliveries) {
      final dayKey = DateFormat('MMM dd').format(delivery.completedAt);
      dailyEarnings[dayKey] = (dailyEarnings[dayKey] ?? 0) + delivery.earnings;
    }

    // Get last 7 days including today
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return DateFormat('MMM dd').format(date);
    });

    // Fill in earnings for each day
    final chartData = last7Days.map((day) {
      return {
        'day': day,
        'earnings': dailyEarnings[day] ?? 0.0,
      };
    }).toList();

    final maxEarnings = chartData.map((d) => d['earnings'] as double).reduce((a, b) => a > b ? a : b);
    final maxHeight = 120.0;

    if (maxEarnings == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.show_chart_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Earnings Trend',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
        child: Column(
          children: [
                  Icon(
                    Icons.show_chart,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'No Earnings Data',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                    'Your earnings trends will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
          ),
        ],
    );
  }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
          children: [
              Icon(
                Icons.show_chart_outlined,
                size: 20,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Earnings Trend',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart bars
                SizedBox(
                  height: maxHeight + 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: chartData.map((data) {
                      final day = data['day'] as String;
                      final earnings = data['earnings'] as double;
                      final barHeight = maxEarnings > 0 
                          ? (earnings / maxEarnings) * maxHeight 
                          : 0.0;
                      
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Earnings amount above bar (if > 0)
                              if (earnings > 0)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '\$${earnings.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              // Bar
                Container(
                                width: double.infinity,
                                height: barHeight > 0 ? barHeight : 2,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                  ),
                ),
                  ),
                              const SizedBox(height: 6),
                              // Day label
                Text(
                                day,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                  ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
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
        ),
      ],
    );
  }

  Widget _buildTipsAnalysis(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
          children: [
              Icon(
                Icons.attach_money_outlined,
                size: 20,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tips Analysis',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 20,
            runSpacing: 12,
          children: [
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'Average Tip',
                  '\$${data.averageTip.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.green,
              ),
            ),
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'Best Tip',
                  '\$${data.bestTip.toStringAsFixed(2)}',
                  Icons.star,
                  Colors.amber,
            ),
              ),
              SizedBox(
                width: 150,
                child: _buildStatItem(
                  context,
                  'Tip Rate',
                  '${data.tipRate.toStringAsFixed(0)}%',
                  Icons.percent,
                  Colors.blue,
                ),
            ),
          ],
        ),
      ),
      ],
    );
  }


  Widget _buildGoalsSection(BuildContext context, EarningsData data) {
    final theme = Theme.of(context);
    final dailyProgress = (data.todayEarnings / data.dailyGoal).clamp(0.0, 1.0);
    final weeklyProgress = (data.weeklyEarnings / data.weeklyGoal).clamp(0.0, 1.0);
    final dailyCompleted = data.todayEarnings >= data.dailyGoal;
    final weeklyCompleted = data.weeklyEarnings >= data.weeklyGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
          children: [
              Icon(
                Icons.flag_outlined,
                size: 20,
                color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Goals & Achievements',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
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
                _buildGoalItem('Daily Goal', data.dailyGoal, data.todayEarnings, dailyProgress, dailyCompleted),
                const SizedBox(height: 16),
                _buildGoalItem('Weekly Goal', data.weeklyGoal, data.weeklyEarnings, weeklyProgress, weeklyCompleted),
                if (dailyCompleted || weeklyCompleted) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.15),
                          Colors.orange.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Achievement Unlocked!',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dailyCompleted && weeklyCompleted
                                    ? 'You\'ve completed both daily and weekly goals! 🏆'
                                    : dailyCompleted
                                        ? 'Daily goal achieved! Keep it up! 🎯'
                                        : 'Weekly goal achieved! Excellent work! 🌟',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.amber.shade800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem(String label, double goal, double current, double progress, bool isCompleted) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.flag,
                  size: 20,
                  color: isCompleted ? Colors.green : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Colors.green.withValues(alpha: 0.15) 
                    : theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green.shade700 : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${current.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCompleted ? Colors.green.shade700 : theme.colorScheme.primary,
              ),
            ),
            Text(
              'of \$${goal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

extension ColorUtils on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromARGB(
      (alpha != null ? (alpha * 255).round() : this.alpha),
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }
} 
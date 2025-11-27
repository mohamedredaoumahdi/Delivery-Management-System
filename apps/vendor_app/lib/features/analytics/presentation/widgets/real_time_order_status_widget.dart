import 'package:flutter/material.dart';

class RealTimeOrderStatusWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isUpdating;
  final VoidCallback onRefresh;

  const RealTimeOrderStatusWidget({
    super.key,
    required this.data,
    required this.isUpdating,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatusCard(
          context,
          icon: Icons.pending_actions,
          title: 'Pending Orders',
          value: (data['pendingOrders'] ?? 0).toString(),
          color: Colors.orange,
        ),
        const SizedBox(height: 4),
        _buildStatusCard(
          context,
          icon: Icons.restaurant,
          title: 'Preparing Orders',
          value: (data['preparingOrders'] ?? 0).toString(),
          color: Colors.blue,
        ),
        const SizedBox(height: 4),
        _buildStatusCard(
          context,
          icon: Icons.check_circle_outline,
          title: 'Ready Orders',
          value: (data['readyOrders'] ?? 0).toString(),
          color: Colors.green,
        ),
        const SizedBox(height: 4),
        _buildStatusCard(
          context,
          icon: Icons.done_all,
          title: 'Completed Today',
          value: (data['completedOrders'] ?? 0).toString(),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
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
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

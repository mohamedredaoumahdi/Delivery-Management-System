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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Order Status Overview',
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
              child: Column(
                children: [
                  _buildStatusRow(
                    'Pending Orders', 
                    data['pendingOrders'] ?? 0, 
                    Colors.orange,
                    context,
                  ),
                  _buildStatusRow(
                    'Preparing Orders', 
                    data['preparingOrders'] ?? 0, 
                    Colors.blue,
                    context,
                  ),
                  _buildStatusRow(
                    'Ready Orders', 
                    data['readyOrders'] ?? 0, 
                    Colors.green,
                    context,
                  ),
                  _buildStatusRow(
                    'Completed Today', 
                    data['completedOrders'] ?? 0, 
                    Colors.purple,
                    context,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, int count, Color color, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              count.toString(),
              key: ValueKey('$label-$count'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
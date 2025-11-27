import 'package:flutter/material.dart';

class RealTimeMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  final bool isPositive;
  final String metricType;
  final bool isUpdating;
  final VoidCallback onRefresh;
  final bool showMiniCard;

  const RealTimeMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.isPositive,
    required this.metricType,
    required this.isUpdating,
    required this.onRefresh,
    this.showMiniCard = false,
  });

  @override
  Widget build(BuildContext context) {
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
        child: showMiniCard ? _buildMiniCard(context) : _buildFullCard(context),
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Row(
      children: [
        // Left side: Icon and Title
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
        // Right side: Value and Change
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isUpdating ? Colors.grey : Colors.black87,
              ),
            ),
            if (change.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPositive && change.contains('+'))
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Colors.green[600],
                    )
                  else if (!isPositive && change.contains('-'))
                    Icon(
                      Icons.trending_down,
                      size: 14,
                      color: Colors.red[600],
                    ),
                  const SizedBox(width: 4),
                  Text(
                    change,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: isUpdating 
                          ? Colors.grey 
                          : (isPositive && change.contains('+') 
                              ? Colors.green[600] 
                              : (!isPositive && change.contains('-')
                                  ? Colors.red[600]
                                  : Colors.grey[600])),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard(BuildContext context) {
    return Row(
      children: [
        // Left side: Icon and Title
        Container(
          padding: const EdgeInsets.all(8),
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
        // Right side: Value and Change
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isUpdating ? Colors.grey : Colors.black87,
              ),
            ),
            if (change.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPositive && change.contains('+'))
                    Icon(
                      Icons.trending_up,
                      size: 12,
                      color: Colors.green[600],
                    )
                  else if (!isPositive && change.contains('-'))
                    Icon(
                      Icons.trending_down,
                      size: 12,
                      color: Colors.red[600],
                    ),
                  const SizedBox(width: 4),
                  Text(
                    change,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: isUpdating 
                          ? Colors.grey 
                          : (isPositive && change.contains('+') 
                              ? Colors.green[600] 
                              : (!isPositive && change.contains('-')
                                  ? Colors.red[600]
                                  : Colors.grey[600])),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

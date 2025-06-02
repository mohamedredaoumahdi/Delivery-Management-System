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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: showMiniCard ? _buildMiniCard() : _buildFullCard(),
          ),
          if (isUpdating)
            Positioned(
              top: 8,
              right: 8,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: isUpdating ? null : onRefresh,
              icon: Icon(
                Icons.refresh,
                size: 16,
                color: isUpdating ? Colors.grey : color,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isUpdating ? Colors.grey : null,
          ),
        ),
        if (change.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: isUpdating 
                  ? Colors.grey 
                  : (isPositive ? Colors.green : Colors.red),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniCard() {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isUpdating ? Colors.grey : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isUpdating ? Colors.grey : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        if (change.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            change,
            style: TextStyle(
              fontSize: 10,
              color: isUpdating 
                  ? Colors.grey 
                  : (isPositive ? Colors.green : Colors.grey[600]),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
} 
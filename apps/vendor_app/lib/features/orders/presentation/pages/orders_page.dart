import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/orders_bloc.dart';
import '../../../../di/injection_container.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load orders when page initializes
    context.read<OrdersBloc>().add(LoadOrders());
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
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OrdersBloc>().add(LoadOrders());
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
          ],
        ),
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading orders...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is OrdersError) {
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
                    'Error loading orders',
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
                      context.read<OrdersBloc>().add(LoadOrders());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is OrdersLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(state.orders),
                _buildOrdersList(_filterOrdersByStatus(state.orders, ['PENDING'])),
                _buildOrdersList(_filterOrdersByStatus(state.orders, ['ACCEPTED', 'PREPARING'])),
                _buildOrdersList(_filterOrdersByStatus(state.orders, ['READY_FOR_PICKUP'])),
              ],
            );
          }

          return const Center(
            child: Text('No orders available'),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
                  color: Theme.of(context).colorScheme.primary,
            ),
              ),
              const SizedBox(height: 24),
            Text(
              'No orders found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here when customers place them',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
              ),
                textAlign: TextAlign.center,
            ),
          ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrdersBloc>().add(LoadOrders());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    final orderId = order['id']?.toString() ?? '';
    final orderNumber = order['orderNumber'] ?? orderId;
    final displayNumber = orderNumber.length >= 7 
        ? orderNumber.substring(0, 7) 
        : orderNumber;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showOrderDetails(order);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayNumber,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: Colors.grey[600],
                          ),
                            const SizedBox(width: 4),
                        Text(
                          order['user']?['name'] ?? 'Unknown Customer',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formatStatus(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Order Items
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatOrderItems(order['items'] ?? []),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Order Time
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
              Text(
                _formatTime(order['createdAt']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue[300]!;
      case 'PREPARING':
        return Colors.blue;
      case 'READY_FOR_PICKUP':
        return Colors.green;
      case 'IN_DELIVERY':
        return Colors.indigo;
      case 'ON_THE_WAY':
        return Colors.deepPurple;
      case 'DELIVERED':
        return Colors.purple;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.pending_actions;
      case 'ACCEPTED':
        return Icons.thumb_up;
      case 'PREPARING':
        return Icons.kitchen;
      case 'READY_FOR_PICKUP':
        return Icons.check_circle;
      case 'IN_DELIVERY':
        return Icons.local_shipping;
      case 'ON_THE_WAY':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.done_all;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  List<Map<String, dynamic>> _filterOrdersByStatus(List<Map<String, dynamic>> orders, List<String> statuses) {
    return orders.where((order) {
      final orderStatus = order['status'].toString().toUpperCase();
      return statuses.any((status) => status.toUpperCase() == orderStatus);
    }).toList();
  }

  String _formatTime(String isoString) {
    final dateTime = DateTime.parse(isoString);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final status = order['status']?.toString().toUpperCase() ?? 'PENDING';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final orderId = order['id']?.toString() ?? '';
    final orderNumber = order['orderNumber'] ?? orderId;
    final displayNumber = orderNumber.length >= 7 
        ? orderNumber.substring(0, 7) 
        : orderNumber;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ),
                
                // Order details content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Header with Status
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                                    displayNumber,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                                  const SizedBox(height: 4),
                        Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: statusColor.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _formatStatus(status),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Customer Information Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                              Text(
                                'Customer Information',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                ),
                                    ),
                                  ],
                              ),
                                const SizedBox(height: 20),
                                _buildDetailRow(
                                  context,
                                  Icons.person_outline,
                                  'Name',
                                  order['user']?['name'] ?? 'Unknown Customer',
                              ),
                                if (order['user']?['phone'] != null) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    context,
                                    Icons.phone,
                                    'Phone',
                                    order['user']['phone'],
                                    isClickable: true,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  context,
                                  Icons.location_on,
                                  'Delivery Address',
                                  order['deliveryAddress'] ?? 'No address provided',
                              ),
                                if (order['deliveryInstructions'] != null) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    context,
                                    Icons.note,
                                    'Special Instructions',
                                    order['deliveryInstructions'],
                                    isImportant: true,
                                  ),
                                ],
                            ],
                          ),
                        ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Order Items Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                        Text(
                                      'Order Items',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                          ),
                                    ),
                                  ],
                        ),
                                const SizedBox(height: 20),
                                if ((order['items'] as List? ?? []).isEmpty)
                                  Text(
                                    'No items',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  )
                                else
                                  ...(order['items'] as List).map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                child: Text(
                                              '${item['quantity'] ?? 1}',
                                  style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['productName'] ?? 'Unknown Item',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (item['instructions'] != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Note: ${item['instructions']}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '\$${((item['totalPrice'] ?? item['productPrice'] ?? 0) as num).toStringAsFixed(2)}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Order Summary Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                          children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                              ),
                            ),
                                    const SizedBox(width: 12),
                            Text(
                                      'Order Summary',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                                const SizedBox(height: 20),
                                _buildSummaryRow(
                                  context,
                                  'Subtotal',
                                  '\$${(order['subtotal'] ?? 0.0).toStringAsFixed(2)}',
                                ),
                                if (order['deliveryFee'] != null && (order['deliveryFee'] as num) > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    context,
                                    'Delivery Fee',
                                    '\$${(order['deliveryFee'] as num).toStringAsFixed(2)}',
                                  ),
                                ],
                                if (order['tax'] != null && (order['tax'] as num) > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    context,
                                    'Tax',
                                    '\$${(order['tax'] as num).toStringAsFixed(2)}',
                                  ),
                                ],
                                if (order['serviceFee'] != null && (order['serviceFee'] as num) > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    context,
                                    'Service Fee',
                                    '\$${(order['serviceFee'] as num).toStringAsFixed(2)}',
                                  ),
                                ],
                                if (order['tip'] != null && (order['tip'] as num) > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    context,
                                    'Tip',
                                    '\$${(order['tip'] as num).toStringAsFixed(2)}',
                                    isTip: true,
                                  ),
                                ],
                                if (order['discount'] != null && (order['discount'] as num) > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    context,
                                    'Discount',
                                    '-\$${(order['discount'] as num).toStringAsFixed(2)}',
                                    isDiscount: true,
                                  ),
                                ],
                                const Divider(height: 24),
                                _buildSummaryRow(
                                  context,
                                  'Total',
                                  '\$${(order['total'] ?? 0.0).toStringAsFixed(2)}',
                                  isTotal: true,
                                ),
                        const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.payment,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                        Text(
                                      'Payment: ${_formatPaymentMethod(order['paymentMethod'])}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Placed ${_formatTime(order['createdAt'])}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                  Container(
                  padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  child: _buildActionButtons(context, order, status),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isClickable = false,
    bool isImportant = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
        Icon(
          icon,
          size: 18,
          color: isImportant 
              ? Colors.orange 
              : Colors.grey[600],
        ),
        const SizedBox(width: 12),
                        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isImportant ? FontWeight.w600 : FontWeight.w500,
                  color: isImportant ? Colors.orange[700] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (isClickable)
          IconButton(
            icon: Icon(
              Icons.phone,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              // TODO: Implement phone call
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    bool isTip = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isTotal ? Colors.black87 : Colors.grey[700],
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDiscount 
                ? Colors.green 
                : isTotal 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.black87,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> order, String status) {
    if (status == 'PENDING') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectOrder(order['id']);
                            },
              icon: const Icon(Icons.close, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                              ),
                            ),
              label: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
            flex: 2,
            child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _acceptOrder(order['id']);
                            },
              icon: const Icon(Icons.check, size: 18),
                            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                              ),
                            ),
              label: const Text(
                'Accept',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }
    
    if (status == 'ACCEPTED') {
      return SizedBox(
                      width: double.infinity,
        child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _startPreparing(order['id']);
                        },
          icon: const Icon(Icons.kitchen, size: 20),
                        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
                          ),
                        ),
          label: const Text(
            'Start Preparing',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
                      ),
                    ),
                  ),
      );
    }
    
    if (status == 'PREPARING') {
      return SizedBox(
                      width: double.infinity,
        child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _markOrderReady(order['id']);
                        },
          icon: const Icon(Icons.check_circle_outline, size: 20),
                        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
                          ),
                        ),
          label: const Text(
            'Mark as Ready',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
                  ),
          ),
            ),
          );
    }
    
    return const SizedBox.shrink();
  }

  String _formatPaymentMethod(String? method) {
    if (method == null) return 'Not specified';
    switch (method.toUpperCase()) {
      case 'CASH_ON_DELIVERY':
        return 'Cash on Delivery';
      case 'CREDIT_CARD':
        return 'Credit Card';
      case 'DEBIT_CARD':
        return 'Debit Card';
      case 'PAYPAL':
        return 'PayPal';
      case 'STRIPE':
        return 'Stripe';
      default:
        return method;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: const Text('Filter options coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      print('🚀 VendorOrders: Accepting order $orderId');
      
      // Call API to update order status to ACCEPTED
      await sl<OrderService>().updateOrderStatus(orderId, 'ACCEPTED');
      
      print('✅ VendorOrders: Order accepted successfully');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh orders list (this will show loading state via BLoC)
      print('🔄 VendorOrders: Refreshing orders list');
      context.read<OrdersBloc>().add(LoadOrders());
      
    } catch (e) {
      print('❌ VendorOrders: Failed to accept order: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Call API to update order status to CANCELLED
      await sl<OrderService>().updateOrderStatus(orderId, 'CANCELLED');
      
      // Close loading dialog safely
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order rejected successfully!'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Refresh orders list
      context.read<OrdersBloc>().add(LoadOrders());
      
    } catch (e) {
      // Close loading dialog safely
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markOrderReady(String orderId) async {
    try {
      print('🚀 VendorOrders: Marking order $orderId as ready');
      
      // Call API to update order status to READY_FOR_PICKUP
      await sl<OrderService>().updateOrderStatus(orderId, 'READY_FOR_PICKUP');
      
      print('✅ VendorOrders: Order marked as ready successfully');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as ready for pickup!'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Refresh orders list (this will show loading state via BLoC)
      print('🔄 VendorOrders: Refreshing orders list');
      context.read<OrdersBloc>().add(LoadOrders());
      
    } catch (e) {
      print('❌ VendorOrders: Failed to mark order as ready: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark order ready: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startPreparing(String orderId) async {
    try {
      print('🚀 VendorOrders: Starting to prepare order $orderId');
      
      // Call API to update order status to PREPARING
      await sl<OrderService>().updateOrderStatus(orderId, 'PREPARING');
      
      print('✅ VendorOrders: Order moved to preparing successfully');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order moved to preparing!'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Refresh orders list (this will show loading state via BLoC)
      print('🔄 VendorOrders: Refreshing orders list');
      context.read<OrdersBloc>().add(LoadOrders());
      
    } catch (e) {
      print('❌ VendorOrders: Failed to start preparing: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start preparing: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
        return 'Accepted';
      case 'PREPARING':
        return 'Preparing';
      case 'READY_FOR_PICKUP':
        return 'Ready';
      case 'IN_DELIVERY':
        return 'In Delivery';
      case 'ON_THE_WAY':
        return 'On The Way';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatOrderItems(List items) {
    if (items.isEmpty) return 'No items';
    
    return items.map((item) {
      final productName = item['productName'] ?? 'Unknown Item';
      final quantity = item['quantity'] ?? 1;
      return '$quantity x $productName';
    }).join(', ');
  }
} 
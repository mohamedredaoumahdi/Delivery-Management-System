import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/widgets/admin_layout.dart';
import '../../data/models/order_model.dart';
import '../../data/order_service.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/admin_action_dialogs.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh(BuildContext context) {
    // Auto-refresh every 30 seconds
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && context.mounted) {
        context.read<OrderBloc>().add(LoadOrderDetails(widget.orderId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;
    final horizontalPadding = isMobile ? 16.0 : 24.0;

    return BlocProvider(
      create: (context) {
        final bloc = OrderBloc(orderService: GetIt.instance<OrderService>())
          ..add(LoadOrderDetails(widget.orderId));
        // Start auto-refresh after bloc is created
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoRefresh(context);
        });
        return bloc;
      },
      child: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<OrderBloc>().add(LoadOrderDetails(widget.orderId));
          }
          if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: AdminLayout(
          showAppBar: false,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
            child: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
              if (state is OrderLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is OrderError) {
                return _ErrorCard(
                  message: state.message,
                  onRetry: () => context.read<OrderBloc>().add(LoadOrderDetails(widget.orderId)),
                );
              }

              if (state is OrderDetailsLoaded) {
                return _OrderDetailsContent(
                  order: state.order,
                  isMobile: isMobile,
                );
              }

              return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDetailsContent extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _OrderDetailsContent({
    required this.order,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isMobile ? 16 : 24),
        _HeaderSection(order: order, isMobile: isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        _AdminActionsSection(order: order, isMobile: isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isMobile ? 1 : 2,
              child: Column(
                children: [
                  _OrderInfoCard(order: order, isMobile: isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _CustomerDetailsCard(order: order, isMobile: isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _VendorDetailsCard(order: order, isMobile: isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _DeliveryDetailsCard(order: order, isMobile: isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                  _DeliveryLocationCard(order: order, isMobile: isMobile),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _OrderItemsCard(order: order, isMobile: isMobile),
                    const SizedBox(height: 24),
                    _PaymentDetailsCard(order: order, isMobile: isMobile),
                    const SizedBox(height: 24),
                    _OrderTimelineCard(order: order, isMobile: isMobile),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 16),
          _OrderItemsCard(order: order, isMobile: isMobile),
          const SizedBox(height: 16),
          _PaymentDetailsCard(order: order, isMobile: isMobile),
          const SizedBox(height: 16),
          _OrderTimelineCard(order: order, isMobile: isMobile),
        ],
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _HeaderSection({
    required this.order,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
          tooltip: 'Back to Orders',
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
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
                          'Order ${order.orderNumber}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: isMobile ? 22 : 28,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: order.statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: order.statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                order.statusDisplayName,
                                style: TextStyle(
                                  color: order.statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminActionsSection extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _AdminActionsSection({
    required this.order,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final canModify = order.status != 'DELIVERED' &&
        order.status != 'CANCELLED' &&
        order.status != 'REFUNDED';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: canModify
                      ? () => _showAssignAgentDialog(context, order)
                      : null,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign Agent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: canModify
                      ? () => _showChangeStatusDialog(context, order)
                      : null,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Change Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: canModify
                      ? () => _showCancelOrderDialog(context, order)
                      : null,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (order.status == 'DELIVERED' || order.status == 'CANCELLED') &&
                          order.status != 'REFUNDED'
                      ? () => _showRefundDialog(context, order)
                      : null,
                  icon: const Icon(Icons.money_off),
                  label: const Text('Refund'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: canModify
                      ? () => _showEditFeesDialog(context, order)
                      : null,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Fees'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignAgentDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AssignDeliveryAgentDialog(order: order),
    );
  }

  void _showChangeStatusDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => ChangeOrderStatusDialog(order: order),
    );
  }

  void _showCancelOrderDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => CancelOrderDialog(order: order),
    );
  }

  void _showRefundDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => RefundOrderDialog(order: order),
    );
  }

  void _showEditFeesDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => EditOrderFeesDialog(order: order),
    );
  }
}

// Continue with other card widgets...
// I'll create them in the next part due to length

class _OrderInfoCard extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _OrderInfoCard({required this.order, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Order Number', value: order.orderNumber),
            _InfoRow(
              label: 'Status',
              value: order.statusDisplayName,
              valueColor: order.statusColor,
            ),
            _InfoRow(
              label: 'Created At',
              value: DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
            ),
            if (order.estimatedDeliveryTime != null)
              _InfoRow(
                label: 'Estimated Delivery',
                value: DateFormat('MMM dd, yyyy • hh:mm a').format(order.estimatedDeliveryTime!),
              ),
            if (order.deliveredAt != null)
              _InfoRow(
                label: 'Delivered At',
                value: DateFormat('MMM dd, yyyy • hh:mm a').format(order.deliveredAt!),
              ),
            if (order.deliveryInstructions != null && order.deliveryInstructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Delivery Instructions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  order.deliveryInstructions!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerDetailsCard extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _CustomerDetailsCard({required this.order, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final customer = order.user;
    if (customer == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 20,
                      ),
                ),
                Row(
                  children: [
                    if (customer['phone'] != null)
                      IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () => _launchPhone(customer['phone']),
                        tooltip: 'Call Customer',
                        color: Colors.green,
                      ),
                    if (customer['email'] != null)
                      IconButton(
                        icon: const Icon(Icons.email),
                        onPressed: () => _launchEmail(customer['email']),
                        tooltip: 'Email Customer',
                        color: Colors.blue,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Name', value: customer['name']?.toString() ?? 'N/A'),
            if (customer['email'] != null)
              _InfoRow(label: 'Email', value: customer['email']?.toString() ?? 'N/A'),
            if (customer['phone'] != null)
              _InfoRow(label: 'Phone', value: customer['phone']?.toString() ?? 'N/A'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Delivery Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _VendorDetailsCard extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _VendorDetailsCard({required this.order, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final shop = order.shop;
    final shopName = shop?['name']?.toString() ?? order.shopName;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vendor Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 20,
                      ),
                ),
            if (shop?['phone'] != null)
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () => _launchPhone(shop?['phone'] as String),
                tooltip: 'Call Vendor',
                color: Colors.green,
              ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Shop Name', value: shopName),
            if (shop != null) ...[
              if (shop['address'] != null)
                _InfoRow(label: 'Address', value: shop['address']?.toString() ?? 'N/A'),
              if (shop['phone'] != null)
                _InfoRow(label: 'Phone', value: shop['phone']?.toString() ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _DeliveryDetailsCard extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _DeliveryDetailsCard({required this.order, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final deliveryPerson = order.deliveryPerson;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Agent',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            if (deliveryPerson != null) ...[
              _InfoRow(
                label: 'Name',
                value: deliveryPerson['name']?.toString() ?? 'N/A',
              ),
              if (deliveryPerson['phone'] != null) ...[
                _InfoRow(
                  label: 'Phone',
                  value: deliveryPerson['phone']?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _launchPhone(deliveryPerson['phone']),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Agent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No delivery agent assigned yet',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _OrderItemsCard extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _OrderItemsCard({required this.order, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final items = order.items ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No items found'),
              )
            else
              ...items.map((item) {
                final product = item['product'] as Map<String, dynamic>?;
                final quantity = item['quantity'] as int? ?? 1;
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final productName = product?['name']?.toString() ?? 'Unknown Product';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (item['instructions'] != null)
                              Text(
                                'Note: ${item['instructions']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'Qty: $quantity',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '\$${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

class _PaymentDetailsCard extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _PaymentDetailsCard({required this.order, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment & Invoice',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Payment Method', value: order.paymentMethod),
            if (order.paymentId != null)
              _InfoRow(label: 'Payment ID', value: order.paymentId!),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _InfoRow(label: 'Subtotal', value: '\$${order.subtotal.toStringAsFixed(2)}'),
            _InfoRow(label: 'Delivery Fee', value: '\$${order.deliveryFee.toStringAsFixed(2)}'),
            _InfoRow(label: 'Service Fee', value: '\$${order.serviceFee.toStringAsFixed(2)}'),
            _InfoRow(label: 'Tax', value: '\$${order.tax.toStringAsFixed(2)}'),
            if (order.discount > 0)
              _InfoRow(
                label: 'Discount',
                value: '-\$${order.discount.toStringAsFixed(2)}',
                valueColor: Colors.green,
              ),
            if (order.tip > 0)
              _InfoRow(label: 'Tip', value: '\$${order.tip.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
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

class _OrderTimelineCard extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _OrderTimelineCard({required this.order, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            _TimelineItem(
              title: 'Order Created',
              time: order.createdAt,
              isCompleted: true,
            ),
            if (order.status != 'PENDING')
              _TimelineItem(
                title: 'Order Accepted',
                time: order.updatedAt,
                isCompleted: true,
              ),
            if (order.status == 'DELIVERED' && order.deliveredAt != null)
              _TimelineItem(
                title: 'Order Delivered',
                time: order.deliveredAt!,
                isCompleted: true,
              ),
            if (order.status == 'CANCELLED')
              _TimelineItem(
                title: 'Order Cancelled',
                time: order.updatedAt,
                isCompleted: true,
                isError: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final DateTime time;
  final bool isCompleted;
  final bool isError;

  const _TimelineItem({
    required this.title,
    required this.time,
    this.isCompleted = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isError
                  ? Colors.red
                  : isCompleted
                      ? Colors.green
                      : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isError ? Colors.red : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(time),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLocationCard extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;

  const _DeliveryLocationCard({
    required this.order,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 18 : 20,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    // Open in Google Maps or external map app
                    final url = 'https://www.google.com/maps/search/?api=1&query=${order.deliveryLatitude},${order.deliveryLongitude}';
                    launchUrl(Uri.parse(url));
                  },
                  tooltip: 'Open in Maps',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: isMobile ? 200 : 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Map View',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Live tracking map integration\ncan be added here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '${order.deliveryLatitude.toStringAsFixed(6)}, ${order.deliveryLongitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Click "Open in Maps" to view the delivery location in Google Maps. Live tracking will be available with map integration.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                'Error loading order',
                style: TextStyle(color: Colors.red[700], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[600],
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

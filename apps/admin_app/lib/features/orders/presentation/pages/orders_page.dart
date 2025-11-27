import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/admin_layout.dart';
import '../../data/models/order_model.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
  }

  void _startAutoRefresh(BuildContext context) {
    // Auto-refresh every 30 seconds
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && context.mounted) {
        context.read<OrderBloc>().add(const RefreshOrders());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(BuildContext context) {
    if (mounted) {
      final bloc = context.read<OrderBloc>();
      final status = _selectedStatus;
      final searchQuery = _searchController.text.isEmpty ? null : _searchController.text.trim();
      
      bloc.add(FilterOrders(
        status: status,
        searchQuery: searchQuery,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 800;
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    
    return BlocProvider(
      create: (context) {
        final bloc = GetIt.instance<OrderBloc>()..add(const LoadOrders());
        // Start auto-refresh after bloc is created
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoRefresh(context);
        });
        return bloc;
      },
      child: Builder(
        builder: (blocContext) => AdminLayout(
          showAppBar: false,
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 0.0, horizontalPadding, 24.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                  // Enhanced Header
                  Padding(
                    padding: EdgeInsets.only(top: isMobile ? 16.0 : 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                Icons.shopping_cart_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All Orders',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontSize: isMobile ? 22 : 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                BlocBuilder<OrderBloc, OrderState>(
                                  builder: (context, state) {
                                    if (state is OrdersLoaded) {
                                      return Text(
                                        '${state.filteredOrders.length} of ${state.orders.length} orders',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                              fontSize: isMobile ? 12 : 14,
                                            ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Active Filters Indicator
                            if (_selectedStatus != null || _searchController.text.isNotEmpty)
                              Container(
                                margin: EdgeInsets.only(right: isMobile ? 8 : 12),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 10 : 14,
                                  vertical: isMobile ? 6 : 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.filter_alt,
                                      size: isMobile ? 14 : 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Filtered',
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Filter Button
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.tune_rounded,
                                  size: isMobile ? 20 : 22,
                                ),
                                onPressed: () => _showFilterDialog(blocContext),
                                tooltip: 'Filter Orders',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  
                  // Enhanced Search Bar
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark 
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search by order number, customer, or shop...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                          _applyFilters(blocContext);
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {});
                                // Apply filters immediately when text changes
                                _applyFilters(blocContext);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  
                  // Orders List
                  BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, state) {
                      if (state is OrderLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      if (state is OrderError) {
                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading orders',
                                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.message,
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.read<OrderBloc>().add(const LoadOrders());
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      
                      if (state is OrdersLoaded) {
                        final orders = state.filteredOrders;
                        
                        if (orders.isEmpty) {
                          final theme = Theme.of(context);
                          final isDark = theme.brightness == Brightness.dark;
                          return Card(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                              child: Container(
                                constraints: BoxConstraints(
                                  minHeight: MediaQuery.of(context).size.height * 0.4,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: isMobile ? 48 : 64,
                                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                                      ),
                                      SizedBox(height: isMobile ? 12 : 16),
                                      Text(
                                        'No orders found',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _selectedStatus != null || _searchController.text.isNotEmpty
                                            ? 'Try adjusting your filters'
                                            : 'Orders will appear here once loaded',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                                          fontSize: isMobile ? 11 : 12,
                                        ),
                                      ),
                                      if (_selectedStatus != null || _searchController.text.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _selectedStatus = null;
                                              _searchController.clear();
                                            });
                                            _applyFilters(blocContext);
                                          },
                                          icon: const Icon(Icons.clear_all, size: 16),
                                          label: const Text('Clear Filters'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return Column(
                          children: [
                            // Active Filters Display
                            if (_selectedStatus != null || _searchController.text.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.filter_alt,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (_selectedStatus != null)
                                            _FilterChip(
                                              label: _getStatusDisplayName(_selectedStatus!),
                                              onRemove: () {
                                                setState(() {
                                                  _selectedStatus = null;
                                                });
                                                _applyFilters(blocContext);
                                              },
                                            ),
                                          if (_searchController.text.isNotEmpty)
                                            _FilterChip(
                                              label: 'Search: "${_searchController.text}"',
                                              onRemove: () {
                                                _searchController.clear();
                                                setState(() {});
                                                _applyFilters(blocContext);
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Orders List
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                                child: Column(
                                  children: [
                                    // Table Header
                                    if (!isMobile)
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Expanded(flex: 2, child: Text('Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(flex: 2, child: Text('Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                            Expanded(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                          ],
                                        ),
                                      ),
                                    if (!isMobile) const SizedBox(height: 8),
                                    // Table Body
                                    ...orders.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final order = entry.value;
                                      return _OrderRow(
                                        order: order,
                                        isMobile: isMobile,
                                        isLast: index == orders.length - 1,
                                        onView: () {
                                          context.go('/orders/${order.id}');
                                        },
                                        onUpdateStatus: () {
                                          _showStatusUpdateDialog(blocContext, order);
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
        ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'ACCEPTED':
        return 'Accepted';
      case 'PREPARING':
        return 'Preparing';
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'IN_DELIVERY':
        return 'In Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'CANCELLATION_REQUESTED':
        return 'Cancellation Requested';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status;
    }
  }

  void _showFilterDialog(BuildContext blocContext) {
    final state = blocContext.read<OrderBloc>().state;
    if (state is! OrdersLoaded) return;

    final orders = state.orders;
    
    // Extract unique values for filters
    final uniqueCustomers = <String, String>{};
    final uniqueVendors = <String, String>{};
    final uniqueDeliveryAgents = <String, String>{};
    final uniquePaymentMethods = <String>{};

    for (final order in orders) {
      // Customers
      if (order.user != null && order.user!['id'] != null) {
        final customerId = order.user!['id'] as String;
        final customerName = order.user!['name'] as String? ?? 'Unknown';
        uniqueCustomers[customerId] = customerName;
      }
      
      // Vendors
      if (order.shopId.isNotEmpty) {
        final vendorName = order.shop?['name']?.toString() ?? order.shopName;
        uniqueVendors[order.shopId] = vendorName;
      }
      
      // Delivery Agents
      if (order.deliveryPersonId != null && order.deliveryPerson != null) {
        final agentId = order.deliveryPersonId!;
        final agentName = order.deliveryPerson!['name'] as String? ?? 'Unknown';
        uniqueDeliveryAgents[agentId] = agentName;
      }
      
      // Payment Methods
      if (order.paymentMethod.isNotEmpty) {
        uniquePaymentMethods.add(order.paymentMethod);
      }
    }

    String? tempStatus = _selectedStatus;
    DateTime? tempStartDate;
    DateTime? tempEndDate;
    String? tempCustomerId;
    String? tempVendorId;
    String? tempDeliveryAgentId;
    String? tempPaymentMethod;

    showDialog(
      context: blocContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text('Filter Orders'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Filter
                  DropdownButtonFormField<String>(
                    initialValue: tempStatus,
                    decoration: InputDecoration(
                      labelText: 'Order Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.filter_list_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Statuses')),
                      DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                      DropdownMenuItem(value: 'ACCEPTED', child: Text('Accepted')),
                      DropdownMenuItem(value: 'PREPARING', child: Text('Preparing')),
                      DropdownMenuItem(value: 'READY_FOR_PICKUP', child: Text('Ready for Pickup')),
                      DropdownMenuItem(value: 'IN_DELIVERY', child: Text('In Delivery')),
                      DropdownMenuItem(value: 'DELIVERED', child: Text('Delivered')),
                      DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'CANCELLATION_REQUESTED', child: Text('Cancellation Requested')),
                      DropdownMenuItem(value: 'REFUNDED', child: Text('Refunded')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Range Filters
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: dialogContext,
                              initialDate: tempStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setDialogState(() {
                                tempStartDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              tempStartDate != null
                                  ? DateFormat('MMM dd, yyyy').format(tempStartDate!)
                                  : 'Select date',
                              style: TextStyle(
                                color: tempStartDate != null ? null : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: dialogContext,
                              initialDate: tempEndDate ?? DateTime.now(),
                              firstDate: tempStartDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setDialogState(() {
                                tempEndDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              tempEndDate != null
                                  ? DateFormat('MMM dd, yyyy').format(tempEndDate!)
                                  : 'Select date',
                              style: TextStyle(
                                color: tempEndDate != null ? null : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Customer Filter
                  if (uniqueCustomers.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: tempCustomerId,
                      decoration: InputDecoration(
                        labelText: 'Customer',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Customers')),
                        ...uniqueCustomers.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempCustomerId = value;
                        });
                      },
                    ),
                  if (uniqueCustomers.isNotEmpty) const SizedBox(height: 16),
                  
                  // Vendor Filter
                  if (uniqueVendors.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: tempVendorId,
                      decoration: InputDecoration(
                        labelText: 'Vendor',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.store),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Vendors')),
                        ...uniqueVendors.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempVendorId = value;
                        });
                      },
                    ),
                  if (uniqueVendors.isNotEmpty) const SizedBox(height: 16),
                  
                  // Delivery Agent Filter
                  if (uniqueDeliveryAgents.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: tempDeliveryAgentId,
                      decoration: InputDecoration(
                        labelText: 'Delivery Agent',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.local_shipping),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Agents')),
                        ...uniqueDeliveryAgents.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempDeliveryAgentId = value;
                        });
                      },
                    ),
                  if (uniqueDeliveryAgents.isNotEmpty) const SizedBox(height: 16),
                  
                  // Payment Method Filter
                  if (uniquePaymentMethods.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: tempPaymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.payment),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Methods')),
                        ...uniquePaymentMethods.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempPaymentMethod = value;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _selectedStatus = null;
                  });
                  blocContext.read<OrderBloc>().add(const FilterOrders());
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _selectedStatus = tempStatus;
                  });
                  blocContext.read<OrderBloc>().add(FilterOrders(
                    status: tempStatus,
                    startDate: tempStartDate,
                    endDate: tempEndDate,
                    customerId: tempCustomerId,
                    vendorId: tempVendorId,
                    deliveryAgentId: tempDeliveryAgentId,
                    paymentMethod: tempPaymentMethod,
                  ));
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, OrderModel order) {
    String? newStatus = order.status;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: order.statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Update Order Status'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: order.statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: order.statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Order #${order.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Current Status:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                _StatusChip(status: order.status, statusColor: order.statusColor),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: newStatus,
                  decoration: InputDecoration(
                    labelText: 'New Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.swap_vert_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
                    DropdownMenuItem(value: 'ACCEPTED', child: Text('Accepted')),
                    DropdownMenuItem(value: 'PREPARING', child: Text('Preparing')),
                    DropdownMenuItem(value: 'READY_FOR_PICKUP', child: Text('Ready for Pickup')),
                    DropdownMenuItem(value: 'IN_DELIVERY', child: Text('In Delivery')),
                    DropdownMenuItem(value: 'DELIVERED', child: Text('Delivered')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      newStatus = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newStatus != null && newStatus != order.status) {
                    context.read<OrderBloc>().add(UpdateOrderStatus(order.id, newStatus!));
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderModel order;
  final bool isMobile;
  final bool isLast;
  final VoidCallback onView;
  final VoidCallback onUpdateStatus;

  const _OrderRow({
    required this.order,
    required this.isMobile,
    this.isLast = false,
    required this.onView,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final customerName = order.user?['name'] ?? 'Unknown';
    final shopName = order.shop?['name'] ?? order.shopName;

    if (isMobile) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      
      return InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: order.statusColor.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: order.statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: order.statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: order.status, statusColor: order.statusColor),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Customer',
                      value: customerName,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.store,
                      label: 'Shop',
                      value: shopName,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.attach_money,
                      label: 'Total',
                      value: '\$${order.total.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onUpdateStatus,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Update'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Order Number & Date
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: order.statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Customer
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Shop
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.store_outlined, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shopName,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Total
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.2),
                ),
              ),
              child: Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Status
          Expanded(
            child: _StatusChip(status: order.status, statusColor: order.statusColor),
          ),
          // Actions
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  onPressed: onView,
                  tooltip: 'View Details',
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onUpdateStatus,
                  tooltip: 'Update Status',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color statusColor;

  const _StatusChip({
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    String displayName;
    switch (status) {
      case 'PENDING':
        displayName = 'Pending';
        break;
      case 'ACCEPTED':
        displayName = 'Accepted';
        break;
      case 'PREPARING':
        displayName = 'Preparing';
        break;
      case 'READY_FOR_PICKUP':
        displayName = 'Ready';
        break;
      case 'IN_DELIVERY':
        displayName = 'In Delivery';
        break;
      case 'DELIVERED':
        displayName = 'Delivered';
        break;
      case 'CANCELLATION_REQUESTED':
        displayName = 'Cancel Req';
        break;
      case 'CANCELLED':
        displayName = 'Cancelled';
        break;
      case 'REFUNDED':
        displayName = 'Refunded';
        break;
      default:
        displayName = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        displayName,
        style: TextStyle(
          color: statusColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Info Row Widget for Mobile View
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight 
              ? Colors.green[700]
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight 
                  ? Colors.green[700]
                  : (isDark ? Colors.grey[200] : Colors.grey[800]),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

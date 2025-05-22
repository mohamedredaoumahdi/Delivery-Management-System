import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';

import '../bloc/order_bloc.dart';
import '../widgets/order_list_item.dart';
import '../widgets/empty_orders.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Load active orders initially
    context.read<OrderBloc>().add(const OrderLoadListEvent(active: true));
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }
    
    final bool isActiveTab = _tabController.index == 0;
    context.read<OrderBloc>().add(OrderLoadListEvent(active: isActiveTab));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Orders'),
            Tab(text: 'Past Orders'),
          ],
          labelStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: theme.textTheme.titleSmall,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Orders Tab
          BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state is OrderLoadingList && state.isActiveTab) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is OrderListLoaded && state.isActiveTab) {
                if (state.orders.isEmpty) {
                  return const EmptyOrders(
                    message: 'You don\'t have any active orders',
                    subMessage: 'Your current orders will appear here',
                  );
                }
                
                return _buildOrderList(context, state.orders);
              } else if (state is OrderError && state.isListError && state.isActiveTab) {
                return _buildErrorView(context, state.message);
              }
              
              // Default loading state
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
          
          // Past Orders Tab
          BlocBuilder<OrderBloc, OrderState>(
            builder: (context, state) {
              if (state is OrderLoadingList && !state.isActiveTab) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is OrderListLoaded && !state.isActiveTab) {
                if (state.orders.isEmpty) {
                  return const EmptyOrders(
                    message: 'You don\'t have any past orders',
                    subMessage: 'Your order history will appear here',
                  );
                }
                
                return _buildOrderList(context, state.orders);
              } else if (state is OrderError && state.isListError && !state.isActiveTab) {
                return _buildErrorView(context, state.message);
              }
              
              // Default loading state
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderList(BuildContext context, List<Order> orders) {
    return RefreshIndicator(
      onRefresh: () async {
        final bool isActiveTab = _tabController.index == 0;
        context.read<OrderBloc>().add(OrderLoadListEvent(active: isActiveTab));
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OrderListItem(
              order: order,
              onTap: () {
                context.push('/orders/${order.id}');
              },
              onTrack: order.status == OrderStatus.inDelivery
                  ? () {
                      context.push('/orders/${order.id}/tracking');
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Failed to load orders',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final bool isActiveTab = _tabController.index == 0;
                context.read<OrderBloc>().add(OrderLoadListEvent(active: isActiveTab));
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
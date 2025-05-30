import 'package:flutter/material.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/order_bloc.dart';
import '../widgets/order_list_item.dart';
import '../widgets/empty_orders.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Cache the last loaded states for both tabs
  OrderListLoaded? _lastActiveOrdersState;
  OrderListLoaded? _lastPastOrdersState;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Close any stale dialogs that might be open from previous pages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closeAnyStaleDialogs();
      _loadInitialData();
    });
  }
  
  void _loadInitialData() {
    print('🚀 OrderListPage: _loadInitialData - Checking current state...');
    
    final currentState = context.read<OrderBloc>().state;
    print('🎧 OrderListPage: Current state on init: ${currentState.runtimeType}');
    
    // Always load active orders when entering the page
    print('🔄 OrderListPage: Loading active orders...');
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
      print('🔄 OrderListPage: Tab is changing, skipping...');
      return;
    }
    
    final bool isActiveTab = _tabController.index == 0;
    print('🔄 OrderListPage: Tab changed to ${isActiveTab ? 'Active' : 'Past'} orders');
    print('📤 OrderListPage _handleTabChange: Adding OrderLoadListEvent(active: $isActiveTab)');
    context.read<OrderBloc>().add(OrderLoadListEvent(active: isActiveTab));
    print('✅ OrderListPage _handleTabChange: OrderLoadListEvent added successfully');
  }

  void _closeAnyStaleDialogs() {
    try {
      int dialogsClosed = 0;
      while (Navigator.canPop(context) && dialogsClosed < 5) {
        Navigator.pop(context);
        dialogsClosed++;
        print('🧹 OrderListPage: Closed stale dialog #$dialogsClosed');
      }
      if (dialogsClosed > 0) {
        print('✅ OrderListPage: Closed $dialogsClosed stale dialogs');
      }
    } catch (e) {
      print('⚠️ OrderListPage: Error closing stale dialogs: $e');
    }
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
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          print('🎧 OrderListPage BlocListener: State changed to ${state.runtimeType}');
          
          // Cache order list states when they're loaded
          if (state is OrderListLoaded) {
            if (state.isActiveTab) {
              _lastActiveOrdersState = state;
              print('💾 OrderListPage: Cached active orders state with ${state.orders.length} orders');
            } else {
              _lastPastOrdersState = state;
              print('💾 OrderListPage: Cached past orders state with ${state.orders.length} orders');
            }
          }
          
          // Handle authentication errors
          if (state is OrderError && state.message.contains('Authentication failed')) {
            print('🔐 OrderListPage: Authentication error detected, redirecting to login...');
            // Clear any stored tokens
            context.read<AuthBloc>().add(AuthLogoutEvent());
            // Navigate to login
            context.go('/login');
            return;
          }
          
          // If we receive OrderPlaced state while on this page, load the orders
          if (state is OrderPlaced) {
            print('🎯 OrderListPage: OrderPlaced detected, loading active orders...');
            print('📤 OrderListPage BlocListener: Adding OrderLoadListEvent(active: true)');
            context.read<OrderBloc>().add(const OrderLoadListEvent(active: true));
            print('✅ OrderListPage BlocListener: OrderLoadListEvent added successfully');
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            // Active Orders Tab
            _buildOrderTab(context, true),
            
            // Past Orders Tab
            _buildOrderTab(context, false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bool isActiveTab = _tabController.index == 0;
          print('🔄 Manual trigger: Loading ${isActiveTab ? 'active' : 'past'} orders...');
          context.read<OrderBloc>().add(OrderLoadListEvent(active: isActiveTab));
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildOrderTab(BuildContext context, bool isActiveTab) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        print('🎧 OrderListPage ${isActiveTab ? 'Active' : 'Past'} Tab - Current state: ${state.runtimeType}');
        
        // Show loading for any loading state or when switching tabs
        if (state is OrderLoadingList) {
          print('📱 OrderListPage: Showing loading for ${isActiveTab ? 'active' : 'past'} tab');
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        // Show orders if loaded and matches current tab
        if (state is OrderListLoaded && state.isActiveTab == isActiveTab) {
          print('✅ OrderListPage: Showing ${state.orders.length} ${isActiveTab ? 'active' : 'past'} orders');
          if (state.orders.isEmpty) {
            return EmptyOrders(
              message: isActiveTab 
                  ? 'You don\'t have any active orders'
                  : 'You don\'t have any past orders',
              subMessage: isActiveTab
                  ? 'Your current orders will appear here'
                  : 'Your order history will appear here',
            );
          }
          
          return _buildOrderList(context, state.orders);
        }
        
        // Show error if it matches current tab
        if (state is OrderError && state.isListError && state.isActiveTab == isActiveTab) {
          print('❌ OrderListPage: Showing error for ${isActiveTab ? 'active' : 'past'} tab');
          return _buildErrorView(context, state.message);
        }
        
        // Handle OrderDetailsLoaded state - use cached state if available
        if (state is OrderDetailsLoaded) {
          print('🔄 OrderListPage: OrderDetailsLoaded detected, using cached ${isActiveTab ? 'active' : 'past'} orders...');
          final cachedState = isActiveTab ? _lastActiveOrdersState : _lastPastOrdersState;
          
          if (cachedState != null) {
            print('✅ OrderListPage: Using cached state with ${cachedState.orders.length} ${isActiveTab ? 'active' : 'past'} orders');
            if (cachedState.orders.isEmpty) {
              return EmptyOrders(
                message: isActiveTab 
                    ? 'You don\'t have any active orders'
                    : 'You don\'t have any past orders',
                subMessage: isActiveTab
                    ? 'Your current orders will appear here'
                    : 'Your order history will appear here',
              );
            }
            return _buildOrderList(context, cachedState.orders);
          } else {
            print('⚠️ OrderListPage: No cached state available, triggering reload...');
            // Only trigger reload if no cached state is available
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<OrderBloc>().add(OrderLoadListEvent(active: isActiveTab));
            });
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }
        
        // For any other state, use cached state if available, otherwise show loading
        final cachedState = isActiveTab ? _lastActiveOrdersState : _lastPastOrdersState;
        if (cachedState != null) {
          print('✅ OrderListPage: Using cached state for unknown state ${state.runtimeType}');
          if (cachedState.orders.isEmpty) {
            return EmptyOrders(
              message: isActiveTab 
                  ? 'You don\'t have any active orders'
                  : 'You don\'t have any past orders',
              subMessage: isActiveTab
                  ? 'Your current orders will appear here'
                  : 'Your order history will appear here',
            );
          }
          return _buildOrderList(context, cachedState.orders);
        }
        
        print('🔄 OrderListPage: Showing default loading state for ${isActiveTab ? 'active' : 'past'} tab, state: ${state.runtimeType}');
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
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
              message.contains('Authentication') ? Icons.lock_outline : Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message.contains('Authentication') ? 'Authentication Required' : 'Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (message.contains('Authentication')) {
                  context.go('/login');
                } else {
                  final bool isActiveTab = _tabController.index == 0;
                  context.read<OrderBloc>().add(OrderLoadListEvent(active: isActiveTab));
                }
              },
              icon: Icon(message.contains('Authentication') ? Icons.login : Icons.refresh),
              label: Text(message.contains('Authentication') ? 'Sign In' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;
  
  // Timer for auto-refresh during tracking
  Timer? _trackingTimer;

  OrderBloc({
    required OrderRepository orderRepository,
  }) : _orderRepository = orderRepository,
       super(const OrderInitial()) {
    on<OrderLoadListEvent>(_onOrderLoadList);
    on<OrderLoadDetailsEvent>(_onOrderLoadDetails);
    on<OrderTrackEvent>(_onOrderTrack);
    on<OrderCancelEvent>(_onOrderCancel);
    on<OrderReorderEvent>(_onOrderReorder);
    on<OrderPlaceEvent>(_onOrderPlace);
    on<OrderUpdateTipEvent>(_onOrderUpdateTip);
    on<OrderRefreshListEvent>(_onOrderRefreshList);
    on<OrderLoadMoreEvent>(_onOrderLoadMore);
    on<OrderAutoRefreshEvent>(_onOrderAutoRefresh);
  }

  Future<void> _onOrderLoadList(
    OrderLoadListEvent event,
    Emitter<OrderState> emit,
  ) async {
    print('🎬 OrderBloc: _onOrderLoadList called with active: ${event.active}');
    
    // Always emit loading state when loading orders
    emit(OrderLoadingList(isActiveTab: event.active));
    print('📤 OrderBloc: Emitted OrderLoadingList state');

    try {
      print('📞 OrderBloc: Calling _orderRepository.getUserOrders...');
      final result = await _orderRepository.getUserOrders(
        status: event.active 
            ? null // Load all active orders
            : null, // Load all past orders - you might want to filter by completed statuses
        page: 1,
        limit: 20,
      );
      print('📋 OrderBloc: Repository call completed');

      result.fold(
        (failure) {
          print('❌ OrderBloc: Repository returned failure: ${failure.message}');
          emit(OrderError(
            failure.message,
            isListError: true,
            isActiveTab: event.active,
          ));
        },
        (orders) {
          print('✅ OrderBloc: Repository returned ${orders.length} orders');
          // Filter orders based on active/past
          final filteredOrders = event.active
              ? orders.where((order) => order.isActive).toList().cast<Order>()
              : orders.where((order) => !order.isActive).toList().cast<Order>();
          
          print('🔍 OrderBloc: After filtering for ${event.active ? 'active' : 'past'} orders: ${filteredOrders.length} orders');
          
          emit(OrderListLoaded(
            orders: filteredOrders,
            hasMore: orders.length >= 20,
            currentPage: 1,
            isActiveTab: event.active,
          ));
          print('📤 OrderBloc: Emitted OrderListLoaded state with ${filteredOrders.length} orders');
        },
      );
    } catch (e) {
      print('💥 OrderBloc: Exception in _onOrderLoadList: $e');
      emit(OrderError(
        'Failed to load orders: $e',
        isListError: true,
        isActiveTab: event.active,
      ));
    }
  }

  Future<void> _onOrderLoadDetails(
    OrderLoadDetailsEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoadingDetails());

    try {
      final result = await _orderRepository.getOrderById(event.orderId);

      result.fold(
        (failure) => emit(OrderError(failure.message, isDetailsError: true)),
        (order) => emit(OrderDetailsLoaded(order)),
      );
    } catch (e) {
      emit(OrderError('Failed to load order details: $e', isDetailsError: true));
    }
  }

  Future<void> _onOrderTrack(
    OrderTrackEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoadingTracking());

    try {
      final result = await _orderRepository.getOrderById(event.orderId);

      result.fold(
        (failure) => emit(OrderError(failure.message, isTrackingError: true)),
        (order) {
          emit(OrderTrackingLoaded(order));
          
          // Start auto-refresh if order is in delivery
          if (order.status == OrderStatus.inDelivery) {
            _startTrackingAutoRefresh(event.orderId);
          } else if (order.status == OrderStatus.delivered) {
            emit(OrderDelivered(order));
          }
        },
      );
    } catch (e) {
      emit(OrderError('Failed to track order: $e', isTrackingError: true));
    }
  }

  Future<void> _onOrderCancel(
    OrderCancelEvent event,
    Emitter<OrderState> emit,
  ) async {
    final currentState = state;
    emit(const OrderCancelling());

    try {
      final result = await _orderRepository.cancelOrder(
        event.orderId,
        reason: event.reason,
      );

      result.fold(
        (failure) => emit(OrderError(failure.message)),
        (order) {
          emit(OrderCancelled(order));
          
          // If we were showing details, update the details
          if (currentState is OrderDetailsLoaded) {
            emit(OrderDetailsLoaded(order));
          }
        },
      );
    } catch (e) {
      emit(OrderError('Failed to cancel order: $e'));
    }
  }

  Future<void> _onOrderReorder(
    OrderReorderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderReordering());

    try {
      // Get the original order details
      final orderResult = await _orderRepository.getOrderById(event.orderId);
      
      await orderResult.fold(
        (failure) async => emit(OrderError(failure.message)),
        (originalOrder) async {
          // Create a new order with the same items
          final result = await _orderRepository.placeOrder(
            shopId: originalOrder.shopId,
            items: originalOrder.items,
            deliveryAddress: originalOrder.deliveryAddress,
            deliveryLatitude: originalOrder.deliveryLatitude,
            deliveryLongitude: originalOrder.deliveryLongitude,
            deliveryInstructions: originalOrder.deliveryInstructions,
            paymentMethod: originalOrder.paymentMethod,
            tip: originalOrder.tip,
          );

          result.fold(
            (failure) => emit(OrderError(failure.message)),
            (newOrder) => emit(OrderReordered(newOrder)),
          );
        },
      );
    } catch (e) {
      emit(OrderError('Failed to reorder: $e'));
    }
  }

  Future<void> _onOrderPlace(
    OrderPlaceEvent event,
    Emitter<OrderState> emit,
  ) async {
    print('🚀 OrderBloc: Starting order placement...');
    emit(const OrderPlacing());

    try {
      print('📞 OrderBloc: Calling repository.placeOrder...');
      final result = await _orderRepository.placeOrder(
        shopId: event.shopId,
        items: event.items,
        deliveryAddress: event.deliveryAddress,
        deliveryLatitude: event.deliveryLatitude,
        deliveryLongitude: event.deliveryLongitude,
        deliveryInstructions: event.deliveryInstructions,
        paymentMethod: event.paymentMethod,
        tip: event.tip,
      );

      print('📋 OrderBloc: Repository call completed, processing result...');
      
      result.fold(
        (failure) {
          print('❌ OrderBloc: Order placement failed: ${failure.message}');
          emit(OrderError(failure.message));
        },
        (order) {
          print('✅ OrderBloc: Order placement successful! Order ID: ${order.id}');
          print('🎯 OrderBloc: Emitting OrderPlaced state...');
          emit(OrderPlaced(order));
          print('✨ OrderBloc: OrderPlaced state emitted successfully!');
        },
      );
    } catch (e) {
      print('💥 OrderBloc: Exception during order placement: $e');
      emit(OrderError('Failed to place order: $e'));
    }
  }

  Future<void> _onOrderUpdateTip(
    OrderUpdateTipEvent event,
    Emitter<OrderState> emit,
  ) async {
    final currentState = state;
    emit(const OrderUpdatingTip());

    try {
      final result = await _orderRepository.updateTip(event.orderId, event.tip);

      result.fold(
        (failure) => emit(OrderError(failure.message)),
        (order) {
          emit(OrderTipUpdated(order));
          
          // If we were showing details, update the details
          if (currentState is OrderDetailsLoaded) {
            emit(OrderDetailsLoaded(order));
          }
        },
      );
    } catch (e) {
      emit(OrderError('Failed to update tip: $e'));
    }
  }

  Future<void> _onOrderRefreshList(
    OrderRefreshListEvent event,
    Emitter<OrderState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is OrderListLoaded) {
      emit(OrderLoadingList(
        isActiveTab: currentState.isActiveTab,
        oldOrders: currentState.orders,
      ));

      try {
        final result = await _orderRepository.getUserOrders(
          page: 1,
          limit: 20,
        );

        result.fold(
          (failure) => emit(OrderError(
            failure.message,
            isListError: true,
            isActiveTab: currentState.isActiveTab,
          )),
          (orders) {
            // Filter orders based on active/past
            final filteredOrders = currentState.isActiveTab
                ? orders.where((order) => order.isActive).toList().cast<Order>()
                : orders.where((order) => !order.isActive).toList().cast<Order>();
                
            emit(OrderListLoaded(
              orders: filteredOrders,
              hasMore: orders.length >= 20,
              currentPage: 1,
              isActiveTab: currentState.isActiveTab,
            ));
          },
        );
      } catch (e) {
        emit(OrderError(
          'Failed to refresh orders: $e',
          isListError: true,
          isActiveTab: currentState.isActiveTab,
        ));
      }
    }
  }

  Future<void> _onOrderLoadMore(
    OrderLoadMoreEvent event,
    Emitter<OrderState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is OrderListLoaded && currentState.hasMore) {
      emit(OrderLoadingMore(
        orders: currentState.orders,
        currentPage: currentState.currentPage,
        isActiveTab: currentState.isActiveTab,
      ));

      try {
        final nextPage = currentState.currentPage + 1;
        
        final result = await _orderRepository.getUserOrders(
          page: nextPage,
          limit: 20,
        );

        result.fold(
          (failure) => emit(OrderError(
            failure.message,
            isListError: true,
            isActiveTab: currentState.isActiveTab,
          )),
          (newOrders) {
            // Filter new orders based on active/past
            final filteredNewOrders = currentState.isActiveTab
                ? newOrders.where((order) => order.isActive).toList().cast<Order>()
                : newOrders.where((order) => !order.isActive).toList().cast<Order>();
                
            final allOrders = [...currentState.orders, ...filteredNewOrders];
            
            emit(OrderListLoaded(
              orders: allOrders,
              hasMore: newOrders.length >= 20,
              currentPage: nextPage,
              isActiveTab: currentState.isActiveTab,
            ));
          },
        );
      } catch (e) {
        emit(OrderError(
          'Failed to load more orders: $e',
          isListError: true,
          isActiveTab: currentState.isActiveTab,
        ));
      }
    }
  }

  Future<void> _onOrderAutoRefresh(
    OrderAutoRefreshEvent event,
    Emitter<OrderState> emit,
  ) async {
    // This is called by the timer for auto-refresh during tracking
    if (state is OrderTrackingLoaded) {
      try {
        final result = await _orderRepository.getOrderById(event.orderId);

        result.fold(
          (failure) {
            // Don't emit error for auto-refresh failures, just log
            // emit(OrderError(failure.message, isTrackingError: true));
          },
          (order) {
            emit(OrderTrackingLoaded(order));
            
            // Check if order is delivered
            if (order.status == OrderStatus.delivered) {
              _stopTrackingAutoRefresh();
              emit(OrderDelivered(order));
            }
          },
        );
      } catch (e) {
        // Don't emit error for auto-refresh failures
      }
    }
  }

  void _startTrackingAutoRefresh(String orderId) {
    _stopTrackingAutoRefresh(); // Stop any existing timer
    
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 30), // Refresh every 30 seconds
      (timer) {
        add(OrderAutoRefreshEvent(orderId));
      },
    );
  }

  void _stopTrackingAutoRefresh() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  @override
  Future<void> close() {
    _stopTrackingAutoRefresh();
    return super.close();
  }
}
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../di/injection_container.dart';

// Events
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {}

// States
abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Map<String, dynamic>> orders;

  const OrdersLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Bloc
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderService orderService;

  OrdersBloc({
    required this.orderService,
  }) : super(OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    print('🚀 OrdersBloc: LoadOrders event received');
    print('📊 OrdersBloc: Current state: ${state.runtimeType}');
    
    emit(OrdersLoading());
    print('📊 OrdersBloc: Emitted OrdersLoading state');
    
    try {
      print('📡 OrdersBloc: Calling orderService.getOrders()');
      final orders = await orderService.getOrders();
      print('✅ OrdersBloc: Received ${orders.length} orders');
      
      emit(OrdersLoaded(orders: orders));
      print('📊 OrdersBloc: Emitted OrdersLoaded state with ${orders.length} orders');
    } catch (e) {
      print('❌ OrdersBloc: Error loading orders: $e');
      emit(OrdersError(message: e.toString()));
      print('📊 OrdersBloc: Emitted OrdersError state: $e');
    }
  }
} 
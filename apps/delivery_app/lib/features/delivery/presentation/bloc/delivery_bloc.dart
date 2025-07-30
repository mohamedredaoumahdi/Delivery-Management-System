import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/delivery_service.dart';

part 'delivery_event.dart';
part 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryService _deliveryService;

  DeliveryBloc(this._deliveryService) : super(const DeliveryInitial()) {
    on<DeliveryLoadAvailableEvent>(_onLoadAvailable);
    on<DeliveryLoadDetailsEvent>(_onLoadDetails);
    on<DeliveryAcceptEvent>(_onAccept);
    on<DeliveryUpdateStatusEvent>(_onUpdateStatus);
  }

  Future<void> _onLoadAvailable(
    DeliveryLoadAvailableEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    print('🚀 DeliveryBloc: LoadAvailableEvent received');
    print('📊 DeliveryBloc: Current state: ${state.runtimeType}');
    
    emit(const DeliveryLoading());
    print('📊 DeliveryBloc: State updated to DeliveryLoading');

    try {
      print('🔄 DeliveryBloc: Calling deliveryService.getAvailableOrders()');
      // Call real API to get available orders
      final ordersData = await _deliveryService.getAvailableOrders();
      
      print('✅ DeliveryBloc: Successfully received ${ordersData.length} orders from service');
      print('📦 DeliveryBloc: Raw orders data: $ordersData');
      
      // Convert API response to DeliveryOrder objects
      final deliveries = ordersData.map((orderData) {
        final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
        final shopName = orderData['shopName'] ?? orderData['shop_name'] ?? 'Unknown Shop';
        final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
        final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
        
        print('🔄 DeliveryBloc: Converting order data: ${orderData['id']}');
        print('   Customer: $customerName');
        print('   Shop: $shopName');
        print('   Order: $orderNumber');
        print('   Address: $deliveryAddress');
        
        final deliveryOrder = DeliveryOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderNumber,
          customerName: customerName,
          deliveryAddress: deliveryAddress,
          total: (orderData['total'] ?? 0).toDouble(),
          distance: 2.0, // TODO: Calculate actual distance
          status: DeliveryStatus.pending,
        );
        
        print('✅ DeliveryBloc: Converted to DeliveryOrder: Customer=$customerName, Address=$deliveryAddress, Total=\$${deliveryOrder.total}');
        return deliveryOrder;
      }).toList();
      
      print('📦 DeliveryBloc: Final deliveries list: ${deliveries.length} items');
      print('📊 DeliveryBloc: Emitting DeliveryLoaded state');
      
      emit(DeliveryLoaded(deliveries));
      
      print('✅ DeliveryBloc: Successfully emitted DeliveryLoaded with ${deliveries.length} deliveries');
      
    } catch (error) {
      print('❌ DeliveryBloc: Error occurred while loading available orders');
      print('❌ DeliveryBloc: Error details: $error');
      print('❌ DeliveryBloc: Error type: ${error.runtimeType}');
      
      emit(DeliveryError(error.toString()));
      
      print('📊 DeliveryBloc: Error state emitted with message: $error');
    }
  }

  Future<void> _onLoadDetails(
    DeliveryLoadDetailsEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    print('🚀 DeliveryBloc: LoadDetailsEvent received for delivery: ${event.deliveryId}');
    print('📊 DeliveryBloc: Current state: ${state.runtimeType}');
    
    emit(const DeliveryLoading());
    print('📊 DeliveryBloc: State updated to DeliveryLoading');

    try {
      print('🔄 DeliveryBloc: Calling deliveryService.getOrderDetails()');
      final orderData = await _deliveryService.getOrderDetails(event.deliveryId);
      print('✅ DeliveryBloc: Successfully received order details');
      print('📦 DeliveryBloc: Order data: $orderData');
      
      // Convert API response to DeliveryOrder
      final customerName = orderData['user']?['name'] ?? orderData['shop']?['name'] ?? 'Unknown Customer';
      final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
      final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
      final total = (orderData['total'] ?? 0).toDouble();
      
      print('🔄 DeliveryBloc: Converting order details:');
      print('   Customer: $customerName');
      print('   Order: $orderNumber');
      print('   Address: $deliveryAddress');
      print('   Total: \$${total}');
      
      final delivery = DeliveryOrder(
        id: event.deliveryId,
        orderNumber: orderNumber,
        customerName: customerName,
        deliveryAddress: deliveryAddress,
        total: total,
        distance: 2.0, // TODO: Calculate actual distance
        status: DeliveryStatus.pending,
      );
      
      print('✅ DeliveryBloc: Converted to DeliveryOrder successfully');
      emit(DeliveryDetailsLoaded(delivery));
      print('📊 DeliveryBloc: Emitted DeliveryDetailsLoaded state');
    } catch (error) {
      print('❌ DeliveryBloc: Error loading order details: $error');
      print('❌ DeliveryBloc: Error type: ${error.runtimeType}');
      emit(DeliveryError(error.toString()));
      print('📊 DeliveryBloc: Emitted DeliveryError state: $error');
    }
  }

  Future<void> _onAccept(
    DeliveryAcceptEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    print('🚀 DeliveryBloc: AcceptEvent received for delivery: ${event.deliveryId}');
    print('📊 DeliveryBloc: Current state: ${state.runtimeType}');
    
    emit(const DeliveryLoading());
    print('📊 DeliveryBloc: State updated to DeliveryLoading');
    
    try {
      print('🔄 DeliveryBloc: Calling deliveryService.acceptOrder()');
      await _deliveryService.acceptOrder(event.deliveryId);
      print('✅ DeliveryBloc: Order accepted successfully');
      
      // Update delivery status
      emit(const DeliveryAccepted());
      print('📊 DeliveryBloc: Emitted DeliveryAccepted state');
      
      // Refresh available orders list
      print('🔄 DeliveryBloc: Refreshing available orders after acceptance');
      add(const DeliveryLoadAvailableEvent());
      
    } catch (error) {
      print('❌ DeliveryBloc: Error accepting order: $error');
      print('❌ DeliveryBloc: Error type: ${error.runtimeType}');
      emit(DeliveryError(error.toString()));
      print('📊 DeliveryBloc: Emitted DeliveryError state: $error');
    }
  }

  Future<void> _onUpdateStatus(
    DeliveryUpdateStatusEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(DeliveryStatusUpdated(event.status));
    } catch (error) {
      emit(DeliveryError(error.toString()));
    }
  }
}

// Mock data models (these would normally be in domain layer)
class DeliveryOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String deliveryAddress;
  final double total;
  final double distance;
  final DeliveryStatus status;
  final DateTime? deliveredAt;

  const DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.deliveryAddress,
    required this.total,
    required this.distance,
    required this.status,
    this.deliveredAt,
  });
}

enum DeliveryStatus { pending, accepted, pickedUp, inTransit, delivered } 
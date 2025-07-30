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
    
    // Only emit loading if not already in a loading state
    if (state is! DeliveryLoading) {
      emit(const DeliveryLoading());
      print('📊 DeliveryBloc: State updated to DeliveryLoading');
    }

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
        final backendStatus = orderData['status'] ?? 'PENDING';
        
        print('🔄 DeliveryBloc: Converting order data: ${orderData['id']}');
        print('   Customer: $customerName');
        print('   Shop: $shopName');
        print('   Order: $orderNumber');
        print('   Address: $deliveryAddress');
        print('   Backend Status: $backendStatus');
        
        // Map backend status to delivery status
        final deliveryStatus = _mapBackendStatusToDeliveryStatus(backendStatus);
        print('   Mapped to Delivery Status: $deliveryStatus');
        
        // Parse order items
        final itemsData = orderData['items'] as List<dynamic>? ?? [];
        final orderItems = itemsData.map((itemData) {
          return OrderItem(
            name: itemData['productName'] ?? 'Unknown Item',
            quantity: itemData['quantity'] ?? 1,
            price: (itemData['productPrice'] ?? 0).toDouble(),
            totalPrice: (itemData['totalPrice'] ?? 0).toDouble(),
          );
        }).toList();
        
        print('   Order Items: ${orderItems.length} items');
        for (final item in orderItems) {
          print('     - ${item.quantity}x ${item.name} @ \$${item.price} = \$${item.totalPrice}');
        }
        
        final deliveryOrder = DeliveryOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderNumber,
          customerName: customerName,
          deliveryAddress: deliveryAddress,
          total: (orderData['total'] ?? 0).toDouble(),
          distance: 2.0, // TODO: Calculate actual distance
          status: deliveryStatus,
          items: orderItems,
          shopName: shopName,
          pickupAddress: orderData['shop']?['address'] ?? 'Unknown Address',
        );
        
        print('✅ DeliveryBloc: Converted to DeliveryOrder: Customer=$customerName, Address=$deliveryAddress, Total=\$${deliveryOrder.total}, Status=$deliveryStatus, Items=${orderItems.length}');
        return deliveryOrder;
      }).toList();
      
      print('📦 DeliveryBloc: Final deliveries list: ${deliveries.length} items');
      print('📊 DeliveryBloc: Emitting DeliveryLoaded state');
      
      emit(DeliveryLoaded(deliveries));
      
      print('✅ DeliveryBloc: Successfully emitted DeliveryLoaded with ${deliveries.length} deliveries');

    } catch (error) {
      print('❌ DeliveryBloc: Error loading available orders: $error');
      print('❌ DeliveryBloc: Error type: ${error.runtimeType}');
      emit(DeliveryError(error.toString()));
      print('📊 DeliveryBloc: Emitted DeliveryError state: $error');
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
      final backendStatus = orderData['status'] ?? 'PENDING';
      
      print('🔄 DeliveryBloc: Converting order details:');
      print('   Customer: $customerName');
      print('   Order: $orderNumber');
      print('   Address: $deliveryAddress');
      print('   Total: \$${total}');
      print('   Backend Status: $backendStatus');
      
      // Map backend status to delivery status
      final deliveryStatus = _mapBackendStatusToDeliveryStatus(backendStatus);
      print('   Mapped to Delivery Status: $deliveryStatus');
      
      // Parse order items from the detailed response
      final itemsData = orderData['items'] as List<dynamic>? ?? [];
      final orderItems = itemsData.map((itemData) {
        return OrderItem(
          name: itemData['productName'] ?? itemData['product']?['name'] ?? 'Unknown Item',
          quantity: itemData['quantity'] ?? 1,
          price: (itemData['productPrice'] ?? itemData['product']?['price'] ?? 0).toDouble(),
          totalPrice: (itemData['totalPrice'] ?? 0).toDouble(),
        );
      }).toList();
      
      print('   Order Items: ${orderItems.length} items');
      for (final item in orderItems) {
        print('     - ${item.quantity}x ${item.name} @ \$${item.price} = \$${item.totalPrice}');
      }
      
      final delivery = DeliveryOrder(
        id: event.deliveryId,
        orderNumber: orderNumber,
        customerName: customerName,
        deliveryAddress: deliveryAddress,
        total: total,
        distance: 2.0, // TODO: Calculate actual distance
        status: deliveryStatus,
        items: orderItems,
        shopName: orderData['shopName'] ?? orderData['shop']?['name'] ?? 'Unknown Restaurant',
        pickupAddress: orderData['shop']?['address'] ?? 'Unknown Address',
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
      
      // Wait a moment before refreshing to allow backend to update
      await Future.delayed(const Duration(milliseconds: 500));
      
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

  /// Maps backend order status to delivery app status
  DeliveryStatus _mapBackendStatusToDeliveryStatus(String backendStatus) {
    switch (backendStatus.toUpperCase()) {
      case 'READY_FOR_PICKUP':
        return DeliveryStatus.readyForPickup; // Order is ready for driver to pick up
      case 'PICKED_UP':
      case 'IN_DELIVERY':
        return DeliveryStatus.pickedUp; // Driver has picked up the order
      case 'ON_THE_WAY':
        return DeliveryStatus.inTransit; // Driver is on the way to customer
      case 'DELIVERED':
        return DeliveryStatus.delivered; // Order has been delivered
      case 'ACCEPTED':
        return DeliveryStatus.accepted; // Driver accepted the order
      default:
        print('⚠️ DeliveryBloc: Unknown backend status: $backendStatus, defaulting to pending');
        return DeliveryStatus.pending;
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
  final List<OrderItem> items;
  final String shopName;
  final String pickupAddress;

  const DeliveryOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.deliveryAddress,
    required this.total,
    required this.distance,
    required this.status,
    this.deliveredAt,
    this.items = const [],
    this.shopName = 'Unknown Restaurant',
    this.pickupAddress = 'Unknown Address',
  });
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;
  final double totalPrice;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });
}

enum DeliveryStatus { pending, readyForPickup, accepted, pickedUp, inTransit, delivered } 
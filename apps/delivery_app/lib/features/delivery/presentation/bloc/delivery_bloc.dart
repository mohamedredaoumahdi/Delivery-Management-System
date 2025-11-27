import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/delivery_service.dart';

part 'delivery_event.dart';
part 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final DeliveryService _deliveryService;

  DeliveryBloc(this._deliveryService) : super(const DeliveryInitial()) {
    on<DeliveryLoadAvailableEvent>(_onLoadAvailable);
    on<DeliveryLoadAssignedEvent>(_onLoadAssigned);
    on<DeliveryLoadDetailsEvent>(_onLoadDetails);
    on<DeliveryAcceptEvent>(_onAccept);
    on<DeliveryUpdateStatusEvent>(_onUpdateStatus);
    on<DeliveryMarkDeliveredEvent>(_onMarkDelivered);
  }

  /// Loads available delivery orders from the API
  /// Converts backend order data to DeliveryOrder models
  Future<void> _onLoadAvailable(
    DeliveryLoadAvailableEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    // Only emit loading if not already in a loading state
    if (state is! DeliveryLoading) {
      emit(const DeliveryLoading());
    }

    try {
      // Call real API to get available orders
      final ordersData = await _deliveryService.getAvailableOrders();
      
      // Convert API response to DeliveryOrder objects
      final deliveries = ordersData.map((orderData) {
        final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
        final shopName = orderData['shopName'] ?? orderData['shop_name'] ?? 'Unknown Shop';
        final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
        final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
        final backendStatus = orderData['status'] ?? 'PENDING';
        
        // Map backend status to delivery status
        final deliveryStatus = _mapBackendStatusToDeliveryStatus(backendStatus);
        
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
        
        return DeliveryOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderNumber,
          customerName: customerName,
          customerPhone: orderData['user']?['phone'],
          deliveryAddress: deliveryAddress,
          total: (orderData['total'] ?? 0).toDouble(),
          subtotal: (orderData['subtotal'] ?? 0).toDouble(),
          deliveryFee: (orderData['deliveryFee'] ?? 0).toDouble(),
          serviceFee: (orderData['serviceFee'] ?? 0).toDouble(),
          tax: (orderData['tax'] ?? 0).toDouble(),
          tip: (orderData['tip'] ?? 0).toDouble(),
          discount: (orderData['discount'] ?? 0).toDouble(),
          paymentMethod: orderData['paymentMethod'],
          distance: 2.0, // TODO: Calculate actual distance using geolocation
          status: deliveryStatus,
          items: orderItems,
          shopName: shopName,
          pickupAddress: orderData['shop']?['address'] ?? 'Unknown Address',
        );
      }).toList();
      
      emit(DeliveryLoaded(deliveries));

    } catch (error) {
      emit(DeliveryError(error.toString()));
    }
  }

  /// Loads assigned delivery orders for the current driver
  Future<void> _onLoadAssigned(
    DeliveryLoadAssignedEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    if (state is! DeliveryLoading) {
      emit(const DeliveryLoading());
    }

    try {
      final ordersData = await _deliveryService.getAssignedOrders();
      
      // Convert API response to DeliveryOrder objects
      final deliveries = ordersData.map((orderData) {
        final customerName = orderData['user']?['name'] ?? 'Unknown Customer';
        final shopName = orderData['shopName'] ?? orderData['shop_name'] ?? 'Unknown Shop';
        final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
        final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
        final backendStatus = orderData['status'] ?? 'PENDING';
        
        // Map backend status to delivery status
        final deliveryStatus = _mapBackendStatusToDeliveryStatus(backendStatus);
        
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
        
        return DeliveryOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderNumber,
          customerName: customerName,
          customerPhone: orderData['user']?['phone'],
          deliveryAddress: deliveryAddress,
          total: (orderData['total'] ?? 0).toDouble(),
          subtotal: (orderData['subtotal'] ?? 0).toDouble(),
          deliveryFee: (orderData['deliveryFee'] ?? 0).toDouble(),
          serviceFee: (orderData['serviceFee'] ?? 0).toDouble(),
          tax: (orderData['tax'] ?? 0).toDouble(),
          tip: (orderData['tip'] ?? 0).toDouble(),
          discount: (orderData['discount'] ?? 0).toDouble(),
          paymentMethod: orderData['paymentMethod'],
          distance: 2.0, // TODO: Calculate actual distance
          status: deliveryStatus,
          items: orderItems,
          shopName: shopName,
          pickupAddress: orderData['shop']?['address'] ?? 'Unknown Address',
        );
      }).toList();
      
      emit(DeliveryLoaded(deliveries));

    } catch (error) {
      emit(DeliveryError(error.toString()));
    }
  }

  /// Loads detailed information for a specific delivery order
  Future<void> _onLoadDetails(
    DeliveryLoadDetailsEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading());

    try {
      final orderData = await _deliveryService.getOrderDetails(event.deliveryId);
      
      // Convert API response to DeliveryOrder
      final customerName = orderData['user']?['name'] ?? orderData['shop']?['name'] ?? 'Unknown Customer';
      final orderNumber = orderData['orderNumber'] ?? orderData['order_number'] ?? '';
      final deliveryAddress = orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? '';
      final total = (orderData['total'] ?? 0).toDouble();
      final backendStatus = orderData['status'] ?? 'PENDING';
      
      // Map backend status to delivery status
      final deliveryStatus = _mapBackendStatusToDeliveryStatus(backendStatus);
      
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
      
      final delivery = DeliveryOrder(
        id: event.deliveryId,
        orderNumber: orderNumber,
        customerName: customerName,
        customerPhone: orderData['user']?['phone'],
        deliveryAddress: deliveryAddress,
        total: total,
        subtotal: (orderData['subtotal'] ?? 0).toDouble(),
        deliveryFee: (orderData['deliveryFee'] ?? 0).toDouble(),
        serviceFee: (orderData['serviceFee'] ?? 0).toDouble(),
        tax: (orderData['tax'] ?? 0).toDouble(),
        tip: (orderData['tip'] ?? 0).toDouble(),
        discount: (orderData['discount'] ?? 0).toDouble(),
        paymentMethod: orderData['paymentMethod'],
        distance: 2.0, // TODO: Calculate actual distance using geolocation
        status: deliveryStatus,
        items: orderItems,
        shopName: orderData['shopName'] ?? orderData['shop']?['name'] ?? 'Unknown Restaurant',
        pickupAddress: orderData['shop']?['address'] ?? 'Unknown Address',
      );
      
      emit(DeliveryDetailsLoaded(delivery));
    } catch (error) {
      emit(DeliveryError(error.toString()));
    }
  }

  /// Accepts a delivery order assignment
  /// Refreshes available orders after successful acceptance
  Future<void> _onAccept(
    DeliveryAcceptEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading());
    
    try {
      await _deliveryService.acceptOrder(event.deliveryId);
      
      // Update delivery status
      emit(const DeliveryAccepted());
      
      // Wait a moment before refreshing to allow backend to update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Refresh available orders list
      add(const DeliveryLoadAvailableEvent());
      
    } catch (error) {
      emit(DeliveryError(error.toString()));
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

  /// Marks a delivery order as delivered
  /// Reloads order details to reflect the updated status
  Future<void> _onMarkDelivered(
    DeliveryMarkDeliveredEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading());
    
    try {
      await _deliveryService.markDelivered(event.deliveryId);
      
      // Emit success state first
      emit(DeliveryMarkedAsDelivered(event.deliveryId));
      
      // Reload the order details to get updated status
      add(DeliveryLoadDetailsEvent(event.deliveryId));
      
    } catch (error) {
      emit(DeliveryError(error.toString()));
    }
  }

  /// Maps backend order status to delivery app status
  /// Handles various backend status formats and converts them to app-specific statuses
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
        // Unknown status - default to pending
        return DeliveryStatus.pending;
    }
  }
}

// Mock data models (these would normally be in domain layer)
class DeliveryOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String? customerPhone;
  final String deliveryAddress;
  final double total;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double tax;
  final double tip;
  final double discount;
  final String? paymentMethod;
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
    this.customerPhone,
    required this.deliveryAddress,
    required this.total,
    this.subtotal = 0.0,
    this.deliveryFee = 0.0,
    this.serviceFee = 0.0,
    this.tax = 0.0,
    this.tip = 0.0,
    this.discount = 0.0,
    this.paymentMethod,
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
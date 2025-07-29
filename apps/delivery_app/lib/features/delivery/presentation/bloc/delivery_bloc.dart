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
    emit(const DeliveryLoading());

    try {
      // Call real API to get available orders
      final ordersData = await _deliveryService.getAvailableOrders();
      
      // Convert API response to DeliveryOrder objects
      final deliveries = ordersData.map((orderData) {
        return DeliveryOrder(
          id: orderData['id'] ?? '',
          orderNumber: orderData['orderNumber'] ?? '',
          customerName: orderData['user']?['name'] ?? 'Unknown Customer',
          deliveryAddress: orderData['deliveryAddress'] ?? '',
          total: (orderData['total'] ?? 0).toDouble(),
          distance: 2.0, // TODO: Calculate actual distance
          status: DeliveryStatus.pending,
        );
      }).toList();
      
      emit(DeliveryLoaded(deliveries));
    } catch (error) {
      emit(DeliveryError(error.toString()));
    }
  }

  Future<void> _onLoadDetails(
    DeliveryLoadDetailsEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(const DeliveryLoading());

    try {
      // Simulate API call to load delivery details
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Mock delivery details
      final delivery = DeliveryOrder(
        id: event.deliveryId,
        orderNumber: 'ORD-${event.deliveryId}',
        customerName: 'John Doe',
        deliveryAddress: '123 Main St, Downtown, City, 12345',
        total: 24.99,
        distance: 2.3,
        status: DeliveryStatus.pending,
      );
      
      emit(DeliveryDetailsLoaded(delivery));
    } catch (error) {
      emit(DeliveryError(error.toString()));
    }
  }

  Future<void> _onAccept(
    DeliveryAcceptEvent event,
    Emitter<DeliveryState> emit,
  ) async {
    try {
      // Call real API to accept the order
      await _deliveryService.acceptOrder(event.deliveryId);
      
      // Update delivery status
      emit(const DeliveryAccepted());
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
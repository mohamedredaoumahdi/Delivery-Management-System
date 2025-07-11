import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'delivery_event.dart';
part 'delivery_state.dart';

@injectable
class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  DeliveryBloc() : super(const DeliveryInitial()) {
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
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock available deliveries
      final deliveries = [
        const DeliveryOrder(
          id: '1',
          orderNumber: 'ORD-001',
          customerName: 'John Doe',
          deliveryAddress: '123 Main St, Downtown',
          total: 24.99,
          distance: 2.3,
          status: DeliveryStatus.pending,
        ),
      ];
      
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
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      
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
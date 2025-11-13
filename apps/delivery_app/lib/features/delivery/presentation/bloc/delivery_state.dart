part of 'delivery_bloc.dart';

abstract class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {
  const DeliveryInitial();
}

class DeliveryLoading extends DeliveryState {
  const DeliveryLoading();
}

class DeliveryLoaded extends DeliveryState {
  final List<DeliveryOrder> deliveries;

  const DeliveryLoaded(this.deliveries);

  @override
  List<Object> get props => [deliveries];
}

class DeliveryDetailsLoaded extends DeliveryState {
  final DeliveryOrder delivery;

  const DeliveryDetailsLoaded(this.delivery);

  @override
  List<Object> get props => [delivery];
}

class DeliveryAccepted extends DeliveryState {
  const DeliveryAccepted();
}

class DeliveryStatusUpdated extends DeliveryState {
  final DeliveryStatus status;

  const DeliveryStatusUpdated(this.status);

  @override
  List<Object> get props => [status];
}

class DeliveryMarkedAsDelivered extends DeliveryState {
  final String deliveryId;

  const DeliveryMarkedAsDelivered(this.deliveryId);

  @override
  List<Object> get props => [deliveryId];
}

class DeliveryError extends DeliveryState {
  final String message;

  const DeliveryError(this.message);

  @override
  List<Object> get props => [message];
} 
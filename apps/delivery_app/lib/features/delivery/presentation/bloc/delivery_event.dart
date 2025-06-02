part of 'delivery_bloc.dart';

abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class DeliveryLoadAvailableEvent extends DeliveryEvent {
  const DeliveryLoadAvailableEvent();
}

class DeliveryAcceptEvent extends DeliveryEvent {
  final String deliveryId;

  const DeliveryAcceptEvent(this.deliveryId);

  @override
  List<Object> get props => [deliveryId];
}

class DeliveryUpdateStatusEvent extends DeliveryEvent {
  final DeliveryStatus status;

  const DeliveryUpdateStatusEvent(this.status);

  @override
  List<Object> get props => [status];
} 
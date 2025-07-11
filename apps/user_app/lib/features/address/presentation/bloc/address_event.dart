import 'package:equatable/equatable.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object?> get props => [];
}

/// Load user addresses
class AddressLoadEvent extends AddressEvent {
  const AddressLoadEvent();
}

/// Create a new address
class AddressCreateEvent extends AddressEvent {
  final String label;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? instructions;
  final bool isDefault;

  const AddressCreateEvent({
    required this.label,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.instructions,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [
        label,
        fullAddress,
        latitude,
        longitude,
        instructions,
        isDefault,
      ];
}

/// Update an existing address
class AddressUpdateEvent extends AddressEvent {
  final String id;
  final String label;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? instructions;
  final bool isDefault;

  const AddressUpdateEvent({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.instructions,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [
        id,
        label,
        fullAddress,
        latitude,
        longitude,
        instructions,
        isDefault,
      ];
}

/// Delete an address
class AddressDeleteEvent extends AddressEvent {
  final String id;

  const AddressDeleteEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Set an address as default
class AddressSetDefaultEvent extends AddressEvent {
  final String id;

  const AddressSetDefaultEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Refresh addresses
class AddressRefreshEvent extends AddressEvent {
  const AddressRefreshEvent();
} 
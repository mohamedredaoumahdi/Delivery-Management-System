import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

abstract class AddressState extends Equatable {
  const AddressState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AddressInitial extends AddressState {
  const AddressInitial();
}

/// Loading state
class AddressLoading extends AddressState {
  const AddressLoading();
}

/// Success state with list of addresses
class AddressLoaded extends AddressState {
  final List<Address> addresses;

  const AddressLoaded({required this.addresses});

  @override
  List<Object?> get props => [addresses];
}

/// Error state
class AddressError extends AddressState {
  final String message;

  const AddressError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Success state after creating an address
class AddressCreated extends AddressState {
  final Address address;

  const AddressCreated({required this.address});

  @override
  List<Object?> get props => [address];
}

/// Success state after updating an address
class AddressUpdated extends AddressState {
  final Address address;

  const AddressUpdated({required this.address});

  @override
  List<Object?> get props => [address];
}

/// Success state after deleting an address
class AddressDeleted extends AddressState {
  final String addressId;

  const AddressDeleted({required this.addressId});

  @override
  List<Object?> get props => [addressId];
}

/// Success state after setting default address
class AddressDefaultSet extends AddressState {
  final Address address;

  const AddressDefaultSet({required this.address});

  @override
  List<Object?> get props => [address];
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';

import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRepository _addressRepository;

  AddressBloc({
    required AddressRepository addressRepository,
  })  : _addressRepository = addressRepository,
        super(const AddressInitial()) {
    on<AddressLoadEvent>(_onLoadAddresses);
    on<AddressCreateEvent>(_onCreateAddress);
    on<AddressUpdateEvent>(_onUpdateAddress);
    on<AddressDeleteEvent>(_onDeleteAddress);
    on<AddressSetDefaultEvent>(_onSetDefaultAddress);
    on<AddressRefreshEvent>(_onRefreshAddresses);
  }

  Future<void> _onLoadAddresses(
    AddressLoadEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await _addressRepository.getAddresses();

    result.fold(
      (failure) => emit(AddressError(message: failure.message)),
      (addresses) => emit(AddressLoaded(addresses: addresses)),
    );
  }

  Future<void> _onCreateAddress(
    AddressCreateEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await _addressRepository.createAddress(
      label: event.label,
      fullAddress: event.fullAddress,
      latitude: event.latitude,
      longitude: event.longitude,
      instructions: event.instructions,
      isDefault: event.isDefault,
    );

    result.fold(
      (failure) => emit(AddressError(message: failure.message)),
      (address) => emit(AddressCreated(address: address)),
    );
  }

  Future<void> _onUpdateAddress(
    AddressUpdateEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await _addressRepository.updateAddress(
      id: event.id,
      label: event.label,
      fullAddress: event.fullAddress,
      latitude: event.latitude,
      longitude: event.longitude,
      instructions: event.instructions,
      isDefault: event.isDefault,
    );

    result.fold(
      (failure) => emit(AddressError(message: failure.message)),
      (address) => emit(AddressUpdated(address: address)),
    );
  }

  Future<void> _onDeleteAddress(
    AddressDeleteEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await _addressRepository.deleteAddress(event.id);

    result.fold(
      (failure) => emit(AddressError(message: failure.message)),
      (_) => emit(AddressDeleted(addressId: event.id)),
    );
  }

  Future<void> _onSetDefaultAddress(
    AddressSetDefaultEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await _addressRepository.setDefaultAddress(event.id);

    result.fold(
      (failure) => emit(AddressError(message: failure.message)),
      (address) => emit(AddressDefaultSet(address: address)),
    );
  }

  Future<void> _onRefreshAddresses(
    AddressRefreshEvent event,
    Emitter<AddressState> emit,
  ) async {
    add(const AddressLoadEvent());
  }
} 
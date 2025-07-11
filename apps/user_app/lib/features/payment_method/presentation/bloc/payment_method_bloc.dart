import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';

import 'payment_method_event.dart';
import 'payment_method_state.dart';

class PaymentMethodBloc extends Bloc<PaymentMethodEvent, PaymentMethodState> {
  final PaymentMethodRepository _paymentMethodRepository;

  PaymentMethodBloc({
    required PaymentMethodRepository paymentMethodRepository,
  })  : _paymentMethodRepository = paymentMethodRepository,
        super(const PaymentMethodInitial()) {
    on<PaymentMethodLoadEvent>(_onLoadPaymentMethods);
    on<PaymentMethodCreateEvent>(_onCreatePaymentMethod);
    on<PaymentMethodUpdateEvent>(_onUpdatePaymentMethod);
    on<PaymentMethodDeleteEvent>(_onDeletePaymentMethod);
    on<PaymentMethodSetDefaultEvent>(_onSetDefaultPaymentMethod);
    on<PaymentMethodRefreshEvent>(_onRefreshPaymentMethods);
  }

  Future<void> _onLoadPaymentMethods(
    PaymentMethodLoadEvent event,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(const PaymentMethodLoading());

    final result = await _paymentMethodRepository.getPaymentMethods();

    result.fold(
      (failure) => emit(PaymentMethodError(message: failure.message)),
      (paymentMethods) => emit(PaymentMethodLoaded(paymentMethods: paymentMethods)),
    );
  }

  Future<void> _onCreatePaymentMethod(
    PaymentMethodCreateEvent event,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(const PaymentMethodLoading());

    final result = await _paymentMethodRepository.createPaymentMethod(
      type: event.type,
      label: event.label,
      cardLast4: event.cardLast4,
      cardBrand: event.cardBrand,
      cardExpiryMonth: event.cardExpiryMonth,
      cardExpiryYear: event.cardExpiryYear,
      cardHolderName: event.cardHolderName,
      walletEmail: event.walletEmail,
      walletProvider: event.walletProvider,
      bankName: event.bankName,
      bankAccountLast4: event.bankAccountLast4,
      isDefault: event.isDefault,
    );

    result.fold(
      (failure) => emit(PaymentMethodError(message: failure.message)),
      (paymentMethod) => emit(PaymentMethodCreated(paymentMethod: paymentMethod)),
    );
  }

  Future<void> _onUpdatePaymentMethod(
    PaymentMethodUpdateEvent event,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(const PaymentMethodLoading());

    final result = await _paymentMethodRepository.updatePaymentMethod(
      id: event.id,
      label: event.label,
      cardExpiryMonth: event.cardExpiryMonth,
      cardExpiryYear: event.cardExpiryYear,
      cardHolderName: event.cardHolderName,
      walletEmail: event.walletEmail,
      bankName: event.bankName,
      isDefault: event.isDefault,
    );

    result.fold(
      (failure) => emit(PaymentMethodError(message: failure.message)),
      (paymentMethod) => emit(PaymentMethodUpdated(paymentMethod: paymentMethod)),
    );
  }

  Future<void> _onDeletePaymentMethod(
    PaymentMethodDeleteEvent event,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(const PaymentMethodLoading());

    final result = await _paymentMethodRepository.deletePaymentMethod(event.id);

    result.fold(
      (failure) => emit(PaymentMethodError(message: failure.message)),
      (_) => emit(const PaymentMethodDeleted()),
    );
  }

  Future<void> _onSetDefaultPaymentMethod(
    PaymentMethodSetDefaultEvent event,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(const PaymentMethodLoading());

    final result = await _paymentMethodRepository.setDefaultPaymentMethod(event.id);

    result.fold(
      (failure) => emit(PaymentMethodError(message: failure.message)),
      (paymentMethod) => emit(PaymentMethodDefaultSet(paymentMethod: paymentMethod)),
    );
  }

  Future<void> _onRefreshPaymentMethods(
    PaymentMethodRefreshEvent event,
    Emitter<PaymentMethodState> emit,
  ) async {
    // Use the same logic as load but don't emit loading state
    final result = await _paymentMethodRepository.getPaymentMethods();

    result.fold(
      (failure) => emit(PaymentMethodError(message: failure.message)),
      (paymentMethods) => emit(PaymentMethodLoaded(paymentMethods: paymentMethods)),
    );
  }
} 
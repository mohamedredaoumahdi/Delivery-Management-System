import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

abstract class PaymentMethodState extends Equatable {
  const PaymentMethodState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is created
class PaymentMethodInitial extends PaymentMethodState {
  const PaymentMethodInitial();
}

/// State when payment methods are being loaded
class PaymentMethodLoading extends PaymentMethodState {
  const PaymentMethodLoading();
}

/// State when payment methods are successfully loaded
class PaymentMethodLoaded extends PaymentMethodState {
  final List<UserPaymentMethod> paymentMethods;

  const PaymentMethodLoaded({required this.paymentMethods});

  @override
  List<Object?> get props => [paymentMethods];
}

/// State when an error occurs
class PaymentMethodError extends PaymentMethodState {
  final String message;

  const PaymentMethodError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State when a payment method is successfully created
class PaymentMethodCreated extends PaymentMethodState {
  final UserPaymentMethod paymentMethod;

  const PaymentMethodCreated({required this.paymentMethod});

  @override
  List<Object?> get props => [paymentMethod];
}

/// State when a payment method is successfully updated
class PaymentMethodUpdated extends PaymentMethodState {
  final UserPaymentMethod paymentMethod;

  const PaymentMethodUpdated({required this.paymentMethod});

  @override
  List<Object?> get props => [paymentMethod];
}

/// State when a payment method is successfully deleted
class PaymentMethodDeleted extends PaymentMethodState {
  const PaymentMethodDeleted();
}

/// State when a payment method is successfully set as default
class PaymentMethodDefaultSet extends PaymentMethodState {
  final UserPaymentMethod paymentMethod;

  const PaymentMethodDefaultSet({required this.paymentMethod});

  @override
  List<Object?> get props => [paymentMethod];
} 
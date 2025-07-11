part of 'earnings_bloc.dart';

abstract class EarningsState {
  const EarningsState();
}

class EarningsInitial extends EarningsState {
  const EarningsInitial();
}

class EarningsLoading extends EarningsState {
  const EarningsLoading();
}

class EarningsLoaded extends EarningsState {
  final EarningsData data;
  const EarningsLoaded(this.data);
}

class EarningsError extends EarningsState {
  final String message;
  const EarningsError(this.message);
} 
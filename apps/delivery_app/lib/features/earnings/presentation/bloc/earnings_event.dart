part of 'earnings_bloc.dart';

abstract class EarningsEvent extends Equatable {
  const EarningsEvent();

  @override
  List<Object?> get props => [];
}

class EarningsLoadEvent extends EarningsEvent {
  const EarningsLoadEvent();
}

class EarningsRefreshEvent extends EarningsEvent {
  const EarningsRefreshEvent();
} 
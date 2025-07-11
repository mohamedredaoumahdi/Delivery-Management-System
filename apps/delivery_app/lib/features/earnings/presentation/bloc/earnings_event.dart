part of 'earnings_bloc.dart';

abstract class EarningsEvent {
  const EarningsEvent();
}

class EarningsLoadEvent extends EarningsEvent {
  const EarningsLoadEvent();
}

class EarningsRefreshEvent extends EarningsEvent {
  const EarningsRefreshEvent();
}

class EarningsPeriodChangedEvent extends EarningsEvent {
  final String period;
  const EarningsPeriodChangedEvent(this.period);
} 
part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// Load initial data for home page
class HomeLoadEvent extends HomeEvent {
  const HomeLoadEvent();
}

/// Refresh home page data
class HomeRefreshEvent extends HomeEvent {
  const HomeRefreshEvent();
}

/// Load user location
class HomeLoadUserLocationEvent extends HomeEvent {
  const HomeLoadUserLocationEvent();
}
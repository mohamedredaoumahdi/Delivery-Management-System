part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Loading state
class HomeLoading extends HomeState {
  final double? latitude;
  final double? longitude;

  const HomeLoading({
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Loading location state
class HomeLoadingLocation extends HomeState {
  final double? latitude;
  final double? longitude;

  const HomeLoadingLocation({
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Loaded state
class HomeLoaded extends HomeState {
  final double? latitude;
  final double? longitude;

  const HomeLoaded({
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Error state
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}

/// Location error state
class HomeLocationError extends HomeState {
  final String message;
  final double? latitude;
  final double? longitude;

  const HomeLocationError(
    this.message, {
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [message, latitude, longitude];
}
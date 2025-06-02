part of 'location_bloc.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

/// Initial location state
class LocationInitial extends LocationState {
  const LocationInitial();
}

/// Location is being enabled
class LocationEnabling extends LocationState {
  const LocationEnabling();
}

/// Location is enabled and available
class LocationEnabled extends LocationState {
  final Position? currentPosition;

  const LocationEnabled({this.currentPosition});

  @override
  List<Object?> get props => [currentPosition];
}

/// Location is disabled
class LocationDisabled extends LocationState {
  final bool permissionDenied;
  final bool serviceDisabled;

  const LocationDisabled({
    required this.permissionDenied,
    required this.serviceDisabled,
  });

  @override
  List<Object> get props => [permissionDenied, serviceDisabled];
}

/// Location error
class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object> get props => [message];
} 
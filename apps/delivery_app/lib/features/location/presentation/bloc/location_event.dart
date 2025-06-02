part of 'location_bloc.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

/// Check current location status
class LocationCheckStatusEvent extends LocationEvent {
  const LocationCheckStatusEvent();
}

/// Enable location services
class LocationEnableEvent extends LocationEvent {
  const LocationEnableEvent();
}

/// Update current location
class LocationUpdateEvent extends LocationEvent {
  const LocationUpdateEvent();
}

/// Stop location tracking
class LocationStopTrackingEvent extends LocationEvent {
  const LocationStopTrackingEvent();
} 
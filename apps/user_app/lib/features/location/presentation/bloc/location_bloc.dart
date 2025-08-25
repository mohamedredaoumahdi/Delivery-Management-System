import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core/core.dart';

import '../../../../core/location/location_service.dart';

// Events
abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LocationRequestPermission extends LocationEvent {}

class LocationGetCurrentLocation extends LocationEvent {}

class LocationGetLastKnownLocation extends LocationEvent {}

class LocationUpdateLocation extends LocationEvent {
  final double latitude;
  final double longitude;

  const LocationUpdateLocation({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

// States
abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationPermissionDenied extends LocationState {
  final String message;

  const LocationPermissionDenied(this.message);

  @override
  List<Object?> get props => [message];
}

class LocationLoaded extends LocationState {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const LocationLoaded({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, timestamp];
}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService _locationService;
  final LoggerService _logger;

  LocationBloc({
    required LocationService locationService,
    required LoggerService logger,
  })  : _locationService = locationService,
        _logger = logger,
        super(LocationInitial()) {
    
    on<LocationRequestPermission>(_onRequestPermission);
    on<LocationGetCurrentLocation>(_onGetCurrentLocation);
    on<LocationGetLastKnownLocation>(_onGetLastKnownLocation);
    on<LocationUpdateLocation>(_onUpdateLocation);
  }

  Future<void> _onRequestPermission(
    LocationRequestPermission event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    
    try {
      final hasPermission = await _locationService.requestLocationPermission();
      if (hasPermission) {
        // Try to get last known location first (faster)
        final position = await _locationService.getLastKnownLocation();
        if (position != null) {
          emit(LocationLoaded(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: position.timestamp,
          ));
        } else {
          emit(const LocationError('Could not get location'));
        }
      } else {
        emit(const LocationPermissionDenied('Location permission denied'));
      }
    } catch (e) {
      _logger.e('Error requesting location permission', e);
      emit(LocationError(e.toString()));
    }
  }

  Future<void> _onGetCurrentLocation(
    LocationGetCurrentLocation event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        emit(LocationLoaded(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
        ));
      } else {
        emit(const LocationError('Could not get current location'));
      }
    } catch (e) {
      _logger.e('Error getting current location', e);
      emit(LocationError(e.toString()));
    }
  }

  Future<void> _onGetLastKnownLocation(
    LocationGetLastKnownLocation event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    
    try {
      final position = await _locationService.getLastKnownLocation();
      if (position != null) {
        emit(LocationLoaded(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
        ));
      } else {
        emit(const LocationError('No last known location available'));
      }
    } catch (e) {
      _logger.e('Error getting last known location', e);
      emit(LocationError(e.toString()));
    }
  }

  void _onUpdateLocation(
    LocationUpdateLocation event,
    Emitter<LocationState> emit,
  ) {
    emit(LocationLoaded(
      latitude: event.latitude,
      longitude: event.longitude,
      timestamp: DateTime.now(),
    ));
  }
}

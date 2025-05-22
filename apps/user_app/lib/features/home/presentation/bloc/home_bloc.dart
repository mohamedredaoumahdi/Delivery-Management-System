import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<HomeLoadEvent>(_onHomeLoad);
    on<HomeRefreshEvent>(_onHomeRefresh);
    on<HomeLoadUserLocationEvent>(_onHomeLoadUserLocation);
  }

  Future<void> _onHomeLoad(
    HomeLoadEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    
    try {
      // Get user location
      final userLocation = await _getUserLocation();
      
      emit(HomeLoaded(
        latitude: userLocation?.latitude,
        longitude: userLocation?.longitude,
      ));
    } catch (e) {
      emit(HomeError('Failed to load home data: $e'));
    }
  }

  Future<void> _onHomeRefresh(
    HomeRefreshEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Keep current state data
    final currentState = state;
    
    if (currentState is HomeLoaded) {
      emit(HomeLoading(
        latitude: currentState.latitude,
        longitude: currentState.longitude,
      ));
      
      try {
        // Get user location
        final userLocation = await _getUserLocation();
        
        emit(HomeLoaded(
          latitude: userLocation?.latitude ?? currentState.latitude,
          longitude: userLocation?.longitude ?? currentState.longitude,
        ));
      } catch (e) {
        emit(HomeError('Failed to refresh home data: $e'));
      }
    } else {
      add(const HomeLoadEvent());
    }
  }

  Future<void> _onHomeLoadUserLocation(
    HomeLoadUserLocationEvent event,
    Emitter<HomeState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is HomeLoaded) {
      emit(HomeLoadingLocation(
        latitude: currentState.latitude,
        longitude: currentState.longitude,
      ));
      
      try {
        // Get user location
        final userLocation = await _getUserLocation();
        
        if (userLocation != null) {
          emit(HomeLoaded(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude,
          ));
        } else {
          emit(HomeLocationError(
            'Could not get location. Please enable location services.',
            latitude: currentState.latitude,
            longitude: currentState.longitude,
          ));
        }
      } catch (e) {
        emit(HomeLocationError(
          'Failed to get location: $e',
          latitude: currentState.latitude,
          longitude: currentState.longitude,
        ));
      }
    } else {
      add(const HomeLoadEvent());
    }
  }
  
  // Helper method to get user location
  Future<Position?> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return null;
    }
    
    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      return null;
    }
    
    // Get current position
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      // Use last known position as fallback
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (e) {
        // Could not get location
        return null;
      }
    }
  }
}
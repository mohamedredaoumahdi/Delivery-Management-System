import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(const LocationInitial()) {
    on<LocationCheckStatusEvent>(_onCheckStatus);
    on<LocationEnableEvent>(_onEnable);
    on<LocationUpdateEvent>(_onUpdate);
    on<LocationStopTrackingEvent>(_onStopTracking);
  }

  Future<void> _onCheckStatus(
    LocationCheckStatusEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      print('🚀 LocationBloc: _onCheckStatus called');
      // Use geolocator for consistency with PermissionCheckPage
      final geolocatorPermission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      print('🔐 LocationBloc: Geolocator permission status: $geolocatorPermission');
      print('📍 LocationBloc: Service enabled: $serviceEnabled');

      final isGranted = geolocatorPermission == LocationPermission.always || 
                        geolocatorPermission == LocationPermission.whileInUse;
      final isPermanentlyDenied = geolocatorPermission == LocationPermission.deniedForever;

      if (isGranted && serviceEnabled) {
        print('✅ LocationBloc: Location is enabled');
        emit(const LocationEnabled());
      } else {
        print('❌ LocationBloc: Location is disabled');
        print('   - Permission denied: ${!isGranted}');
        print('   - Service disabled: ${!serviceEnabled}');
        emit(LocationDisabled(
          permissionDenied: !isGranted,
          serviceDisabled: !serviceEnabled,
          needsSettings: isPermanentlyDenied,
        ));
      }
    } catch (error) {
      print('❌ LocationBloc: Error in _onCheckStatus: $error');
      emit(LocationError(error.toString()));
    }
  }

  Future<void> _onEnable(
    LocationEnableEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      print('🚀 LocationBloc: _onEnable called');
      emit(const LocationEnabling());
      print('📊 LocationBloc: Emitted LocationEnabling state');

      // Check current permission status first using geolocator
      print('🔐 LocationBloc: Checking current permission status with geolocator...');
      LocationPermission currentPermission = await Geolocator.checkPermission();
      print('🔐 LocationBloc: Current geolocator permission status: $currentPermission');
      
      // If permanently denied, we can't request again - need to open settings
      if (currentPermission == LocationPermission.deniedForever) {
        print('❌ LocationBloc: Permission is permanently denied - need to open settings');
        emit(LocationDisabled(
          permissionDenied: true,
          serviceDisabled: false,
          needsSettings: true, // Add flag to indicate settings need to be opened
        ));
        return;
      }

      // Check and request permission using geolocator
      print('🔐 LocationBloc: Requesting location permission with geolocator...');
      LocationPermission requestedPermission = await Geolocator.requestPermission();
      print('🔐 LocationBloc: Geolocator permission status after request: $requestedPermission');
      
      final isGranted = requestedPermission == LocationPermission.always || 
                        requestedPermission == LocationPermission.whileInUse;
      final isPermanentlyDenied = requestedPermission == LocationPermission.deniedForever;
      
      if (!isGranted) {
        print('❌ LocationBloc: Permission denied');
        emit(LocationDisabled(
          permissionDenied: true,
          serviceDisabled: false,
          needsSettings: isPermanentlyDenied,
        ));
        return;
      }

      // Check if location service is enabled
      print('📍 LocationBloc: Checking if location service is enabled...');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 LocationBloc: Service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('❌ LocationBloc: Location service is disabled');
        emit(const LocationDisabled(
          permissionDenied: false,
          serviceDisabled: true,
          needsSettings: false,
        ));
        return;
      }

      // Get current position to verify everything works
      print('📍 LocationBloc: Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('✅ LocationBloc: Got position: ${position.latitude}, ${position.longitude}');

      emit(LocationEnabled(
        currentPosition: position,
      ));
      print('📊 LocationBloc: Emitted LocationEnabled state with position');
    } catch (error) {
      print('❌ LocationBloc: Error in _onEnable: $error');
      print('❌ LocationBloc: Error type: ${error.runtimeType}');
      emit(LocationError(error.toString()));
    }
  }

  Future<void> _onUpdate(
    LocationUpdateEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      print('🚀 LocationBloc: _onUpdate called');
      print('📊 LocationBloc: Current state: ${state.runtimeType}');
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('✅ LocationBloc: Got updated position: ${position.latitude}, ${position.longitude}');

      if (state is LocationEnabled) {
        emit(LocationEnabled(
          currentPosition: position,
        ));
        print('📊 LocationBloc: Emitted LocationEnabled state with updated position');
      } else {
        print('⚠️ LocationBloc: Cannot update - location is not enabled');
      }
    } catch (error) {
      print('❌ LocationBloc: Error in _onUpdate: $error');
      print('❌ LocationBloc: Error type: ${error.runtimeType}');
      emit(LocationError(error.toString()));
    }
  }

  Future<void> _onStopTracking(
    LocationStopTrackingEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationDisabled(
      permissionDenied: false,
      serviceDisabled: false,
      needsSettings: false,
    ));
  }
} 
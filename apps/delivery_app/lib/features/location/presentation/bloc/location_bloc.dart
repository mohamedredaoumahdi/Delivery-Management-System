import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:injectable/injectable.dart';

part 'location_event.dart';
part 'location_state.dart';

@injectable
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
      final permission = await Permission.location.status;
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (permission.isGranted && serviceEnabled) {
        emit(const LocationEnabled());
      } else {
        emit(LocationDisabled(
          permissionDenied: !permission.isGranted,
          serviceDisabled: !serviceEnabled,
        ));
      }
    } catch (error) {
      emit(LocationError(error.toString()));
    }
  }

  Future<void> _onEnable(
    LocationEnableEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      emit(const LocationEnabling());

      // Check and request permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        emit(const LocationDisabled(
          permissionDenied: true,
          serviceDisabled: false,
        ));
        return;
      }

      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationDisabled(
          permissionDenied: false,
          serviceDisabled: true,
        ));
        return;
      }

      // Get current position to verify everything works
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      emit(LocationEnabled(
        currentPosition: position,
      ));
    } catch (error) {
      emit(LocationError(error.toString()));
    }
  }

  Future<void> _onUpdate(
    LocationUpdateEvent event,
    Emitter<LocationState> emit,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (state is LocationEnabled) {
        emit(LocationEnabled(
          currentPosition: position,
        ));
      }
    } catch (error) {
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
    ));
  }
} 
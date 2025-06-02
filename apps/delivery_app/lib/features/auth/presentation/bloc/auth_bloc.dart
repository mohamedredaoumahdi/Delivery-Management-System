import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthLoginEvent>(_onLogin);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthRegisterEvent>(_onRegister);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Simulate checking stored token
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For demo purposes, we'll assume user is not authenticated initially
      // In real app, check SharedPreferences or secure storage for token
      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation - in real app, validate with backend
      if (event.email == 'driver@example.com' && event.password == 'password') {
        final driver = DriverUser(
          id: '1',
          email: event.email,
          name: 'John Driver',
          phone: '+1234567890',
          vehicleType: 'Car',
          licenseNumber: 'DL123456',
          isActive: true,
        );

        emit(AuthAuthenticated(driver));
      } else {
        emit(const AuthError('Invalid email or password'));
      }
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Simulate logout process
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clear stored token/credentials
      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> _onRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Simulate API call for registration
      await Future.delayed(const Duration(seconds: 2));

      // Mock registration success
      final driver = DriverUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: event.email,
        name: event.name,
        phone: event.phone,
        vehicleType: event.vehicleType,
        licenseNumber: event.licenseNumber,
        isActive: true,
      );

      emit(AuthAuthenticated(driver));
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }
}

/// Driver user model
class DriverUser {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String vehicleType;
  final String licenseNumber;
  final bool isActive;

  const DriverUser({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.licenseNumber,
    required this.isActive,
  });

  DriverUser copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? vehicleType,
    String? licenseNumber,
    bool? isActive,
  }) {
    return DriverUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isActive: isActive ?? this.isActive,
    );
  }
} 
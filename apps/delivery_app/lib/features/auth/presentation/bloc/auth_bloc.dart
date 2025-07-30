import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(const AuthInitial()) {
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
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final userRole = _authService.getCurrentUserRole();
        if (userRole == 'DELIVERY') {
          emit(const AuthAuthenticated(DriverUser(
            id: 'current_user',
            email: 'delivery@example.com',
            name: 'Delivery Driver',
            phone: '+1234567890',
            vehicleType: 'Car',
            licenseNumber: 'DL123456',
            isActive: true,
          )));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    print('🚀 AuthBloc: LoginEvent received for email: ${event.email}');
    print('📊 AuthBloc: Current state: ${state.runtimeType}');
    
    emit(const AuthLoading());
    print('📊 AuthBloc: State updated to AuthLoading');

    try {
      print('🔄 AuthBloc: Calling authService.login()');
      final success = await _authService.login(event.email, event.password);
      
      print('📥 AuthBloc: Login service returned: $success');
      
      if (success) {
        print('✅ AuthBloc: Login successful, creating DriverUser object');
        final driver = DriverUser(
          id: 'current_user',
          email: event.email,
          name: 'Delivery Driver',
          phone: '+1234567890',
          vehicleType: 'Car',
          licenseNumber: 'DL123456',
          isActive: true,
        );
        
        print('👤 AuthBloc: Created driver object: ${driver.email}');
        print('📊 AuthBloc: Emitting AuthAuthenticated state');
        
        emit(AuthAuthenticated(driver));
        
        print('✅ AuthBloc: Successfully emitted AuthAuthenticated state');
      } else {
        print('❌ AuthBloc: Login failed - service returned false');
        emit(const AuthError('Login failed'));
      }
    } catch (error) {
      print('❌ AuthBloc: Exception occurred during login');
      print('❌ AuthBloc: Error details: $error');
      print('❌ AuthBloc: Error type: ${error.runtimeType}');
      
      emit(AuthError(error.toString()));
      
      print('📊 AuthBloc: Error state emitted with message: $error');
    }
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.logout();
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
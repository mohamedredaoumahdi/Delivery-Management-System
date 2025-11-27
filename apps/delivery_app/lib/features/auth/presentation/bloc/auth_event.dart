part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check authentication status
class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}

/// Login event
class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Logout event
class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

/// Register event
class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? phone;
  final String vehicleType;
  final String licenseNumber;

  const AuthRegisterEvent({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
    required this.vehicleType,
    required this.licenseNumber,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        phone,
        vehicleType,
        licenseNumber,
      ];
} 
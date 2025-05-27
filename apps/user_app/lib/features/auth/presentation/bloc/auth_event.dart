part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Check if user is already authenticated
class AuthCheckStatusEvent extends AuthEvent {}

// Login with email and password
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

// Sign up with email and password
class AuthSignupEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? phone;
  final String confirmPassword;

  const AuthSignupEvent({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, password, name, phone, confirmPassword];
}

// Logout
class AuthLogoutEvent extends AuthEvent {}

// Forgot password
class AuthForgotPasswordEvent extends AuthEvent {
  final String email;

  const AuthForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

// Update profile
class AuthUpdateProfileEvent extends AuthEvent {
  final String name;
  final String? phone;
  final String? profilePicture;

  const AuthUpdateProfileEvent({
    required this.name,
    this.phone,
    this.profilePicture,
  });

  @override
  List<Object?> get props => [name, phone, profilePicture];
}

// Change password
class AuthChangePasswordEvent extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const AuthChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [currentPassword, newPassword];
}
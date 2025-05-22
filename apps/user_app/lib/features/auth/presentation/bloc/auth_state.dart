part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

// Initial state
class AuthInitial extends AuthState {}

// Loading state
class AuthLoading extends AuthState {}

// Authenticated state
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

// Unauthenticated state
class AuthUnauthenticated extends AuthState {}

// Error state
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

// Password reset email sent
class AuthPasswordResetSent extends AuthState {}

// Password changed successfully
class AuthPasswordChanged extends AuthState {
  final User user;

  const AuthPasswordChanged(this.user);

  @override
  List<Object> get props => [user];
}
import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  /// Error message
  final String message;
  
  /// Creates a failure with a message
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Server failure (network, API, etc.)
class ServerFailure extends Failure {
  /// HTTP status code (if applicable)
  final int? statusCode;
  
  /// Creates a server failure
  const ServerFailure(super.message, {this.statusCode});
  
  @override
  List<Object> get props => [message, if (statusCode != null) statusCode!];
}

/// Cache failure (local storage)
class CacheFailure extends Failure {
  /// Creates a cache failure
  const CacheFailure(super.message);
}

/// Network failure (no internet connection)
class NetworkFailure extends Failure {
  /// Creates a network failure
  const NetworkFailure(super.message);
}

/// Authentication failure
class AuthFailure extends Failure {
  /// Creates an auth failure
  const AuthFailure(super.message);
}

/// Validation failure (form validation)
class ValidationFailure extends Failure {
  /// Field that failed validation
  final String field;
  
  /// Creates a validation failure
  const ValidationFailure(this.field, String message) : super(message);
  
  @override
  List<Object> get props => [message, field];
}

/// Permission failure (missing permissions)
class PermissionFailure extends Failure {
  /// Creates a permission failure
  const PermissionFailure(super.message);
}

/// Not found failure
class NotFoundFailure extends Failure {
  /// Creates a not found failure
  const NotFoundFailure(super.message);
}

/// Timeout failure
class TimeoutFailure extends Failure {
  /// Creates a timeout failure
  const TimeoutFailure(super.message);
}

/// Unknown failure
class UnknownFailure extends Failure {
  /// Creates an unknown failure
  const UnknownFailure(super.message);
}
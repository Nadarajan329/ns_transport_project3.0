/// Base failure class for domain-layer error handling.
///
/// All specific failure types extend this class, providing a consistent
/// interface for error propagation without exposing implementation details.
abstract class Failure {
  /// Human-readable error message.
  final String message;

  /// Optional stack trace for debugging purposes.
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType(message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode ^ runtimeType.hashCode;
}

/// Failure originating from server/API errors (e.g. 500, timeout).
class ServerFailure extends Failure {
  /// Optional HTTP status code associated with the failure.
  final int? statusCode;

  const ServerFailure({
    required super.message,
    super.stackTrace,
    this.statusCode,
  });

  @override
  String toString() =>
      'ServerFailure(message: $message, statusCode: $statusCode)';
}

/// Failure originating from local cache operations.
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.stackTrace,
  });
}

/// Failure related to authentication or authorization.
class AuthFailure extends Failure {
  /// Optional error code from the auth provider (e.g. 'token_expired').
  final String? errorCode;

  const AuthFailure({
    required super.message,
    super.stackTrace,
    this.errorCode,
  });

  @override
  String toString() =>
      'AuthFailure(message: $message, errorCode: $errorCode)';
}

/// Failure due to network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.stackTrace,
  });
}

/// Failure from input validation errors.
class ValidationFailure extends Failure {
  /// Optional map of field-specific validation errors.
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.stackTrace,
    this.fieldErrors,
  });

  @override
  String toString() =>
      'ValidationFailure(message: $message, fieldErrors: $fieldErrors)';
}

/// Failure related to local/remote storage operations.
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.stackTrace,
  });
}

// ─────────────────────────── App Exception ───────────────────────────────

/// General-purpose exception for the application layer.
///
/// Use this to throw typed exceptions that can be caught and
/// mapped to [Failure] subtypes at the repository boundary.
class AppException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Optional error code for programmatic handling.
  final String? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AppException(code: $code, message: $message)';
    }
    return 'AppException(message: $message)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppException &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}

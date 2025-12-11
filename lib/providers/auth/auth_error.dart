/// Base sealed class for authentication errors.
///
/// Enables exhaustive pattern matching for type-safe error handling.
/// All error types extend this base class and provide specific context.
sealed class AuthError {
  /// Human-readable error message.
  final String message;

  const AuthError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => '$runtimeType: $message';
}

/// No session token found in storage.
final class NoSessionTokenError extends AuthError {
  const NoSessionTokenError() : super('No session token found');
}

/// Session token has expired and cannot be refreshed.
final class SessionTokenExpiredError extends AuthError {
  const SessionTokenExpiredError() : super('Session token expired');
}

/// Token refresh operation failed.
final class TokenRefreshError extends AuthError {
  /// Original error that caused the refresh failure.
  final Object? cause;

  const TokenRefreshError([this.cause]) : super('Token refresh failed');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenRefreshError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          cause == other.cause;

  @override
  int get hashCode => Object.hash(message, cause);

  @override
  String toString() => cause != null
      ? 'TokenRefreshError: $message (cause: $cause)'
      : super.toString();
}

/// Invalid credentials provided (wrong password, etc.).
final class InvalidCredentialsError extends AuthError {
  /// Additional details about the credential validation failure.
  final String? details;

  const InvalidCredentialsError([this.details]) : super('Invalid credentials');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvalidCredentialsError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          details == other.details;

  @override
  int get hashCode => Object.hash(message, details);

  @override
  String toString() => details != null
      ? 'InvalidCredentialsError: $message ($details)'
      : super.toString();
}

/// JNAP API returned an error.
final class JnapError extends AuthError {
  /// JNAP result code (e.g., "ErrorInvalidCredentials").
  final String resultCode;

  /// Original error object from JNAP.
  final Object? cause;

  const JnapError(this.resultCode, [this.cause])
      : super('JNAP error: $resultCode');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JnapError &&
          runtimeType == other.runtimeType &&
          resultCode == other.resultCode &&
          cause == other.cause;

  @override
  int get hashCode => Object.hash(resultCode, cause);

  @override
  String toString() => cause != null
      ? 'JnapError: $resultCode (cause: $cause)'
      : 'JnapError: $resultCode';
}

/// Cloud API returned an error.
final class CloudApiError extends AuthError {
  /// Cloud API error code (e.g., "INVALID_SESSION_TOKEN").
  final String? code;

  /// Original error object from cloud API.
  final Object? cause;

  const CloudApiError(this.code, [this.cause])
      : super('Cloud API error: $code');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudApiError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          cause == other.cause;

  @override
  int get hashCode => Object.hash(code, cause);

  @override
  String toString() => cause != null
      ? 'CloudApiError: ${code ?? 'unknown'} (cause: $cause)'
      : 'CloudApiError: ${code ?? 'unknown'}';
}

/// Storage operation failed (read/write/delete).
final class StorageError extends AuthError {
  /// Original error that caused the storage failure.
  final Object? cause;

  const StorageError([this.cause]) : super('Storage operation failed');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          cause == other.cause;

  @override
  int get hashCode => Object.hash(message, cause);

  @override
  String toString() => cause != null
      ? 'StorageError: $message (cause: $cause)'
      : super.toString();
}

/// Network request failed.
final class NetworkError extends AuthError {
  /// Original error that caused the network failure.
  final Object? cause;

  const NetworkError([this.cause]) : super('Network error');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          cause == other.cause;

  @override
  int get hashCode => Object.hash(message, cause);

  @override
  String toString() => cause != null
      ? 'NetworkError: $message (cause: $cause)'
      : super.toString();
}

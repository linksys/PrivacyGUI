/// Unified service error hierarchy for all data sources.
///
/// This sealed class serves as the contract between Service layer and Provider layer.
/// All data source errors (JNAP, Cloud, future systems) MUST be mapped to these types.
///
/// Provider layer catches these errors without knowing the underlying data source.
///
/// Example:
/// ```dart
/// // In Service layer - map JNAP errors to ServiceError
/// try {
///   await routerRepository.send(...);
/// } on JNAPError catch (e) {
///   throw switch (e.result) {
///     'ErrorInvalidResetCode' => InvalidResetCodeError(attemptsRemaining: 3),
///     'ErrorAdminAccountLocked' => const AdminAccountLockedError(),
///     _ => UnexpectedError(originalError: e),
///   };
/// }
///
/// // In Provider layer - catch ServiceError only
/// try {
///   await service.verifyCode(code);
/// } on InvalidResetCodeError catch (e) {
///   state = state.copyWith(attemptsRemaining: e.attemptsRemaining);
/// } on AdminAccountLockedError {
///   // Handle locked account
/// }
/// ```
sealed class ServiceError implements Exception {
  const ServiceError();

  /// Human-readable label derived from the class name.
  ///
  /// `NetworkError` → `Network error`, `InvalidCredentialsError` → `Invalid credentials`.
  /// Subtypes with a `message` field override this to append details.
  @override
  String toString() {
    final name = runtimeType.toString();
    final base =
        name.endsWith('Error') ? name.substring(0, name.length - 5) : name;
    // Split into words: before uppercase after lowercase/digit, and before
    // an uppercase letter followed by lowercase after an uppercase run.
    final spaced = base
        .replaceAllMapped(RegExp(r'(?<=[a-z\d])(?=[A-Z])'), (_) => ' ')
        .replaceAllMapped(RegExp(r'(?<=[A-Z])(?=[A-Z][a-z])'), (_) => ' ');
    if (spaced.isEmpty) return 'Unknown error';
    // Lowercase each word unless it's all-uppercase (acronym like VPN, DNS, IP).
    final words = spaced.split(' ');
    final result = words.asMap().entries.map((e) {
      final word = e.value;
      if (word == word.toUpperCase() && word.length > 1) return word;
      if (e.key == 0) return word;
      return word.toLowerCase();
    }).join(' ');
    return result;
  }
}

// ============================================================================
// Authentication & Session Errors
// ============================================================================

/// User not authenticated
final class NotAuthenticatedError extends ServiceError {
  const NotAuthenticatedError();
}

/// Session token is invalid or expired
final class InvalidSessionTokenError extends ServiceError {
  const InvalidSessionTokenError();
}

/// Session token has expired and cannot be refreshed
final class SessionTokenExpiredError extends ServiceError {
  const SessionTokenExpiredError();
}

/// Invalid credentials (username/password combination)
final class InvalidCredentialsError extends ServiceError {
  const InvalidCredentialsError();
}

/// Unauthorized access attempt
final class UnauthorizedError extends ServiceError {
  const UnauthorizedError();
}

// ============================================================================
// Resource Errors
// ============================================================================

/// Requested resource not found
final class ResourceNotFoundError extends ServiceError {
  const ResourceNotFoundError();
}

// ============================================================================
// OTP Errors
// ============================================================================

/// Invalid OTP code
final class InvalidOtpError extends ServiceError {
  const InvalidOtpError();
}

/// OTP code has expired
final class ExpiredOtpError extends ServiceError {
  const ExpiredOtpError();
}

// ============================================================================
// Admin Password Errors
// ============================================================================

/// Admin account is locked
final class AdminAccountLockedError extends ServiceError {
  const AdminAccountLockedError();
}

/// Invalid reset code provided
final class InvalidResetCodeError extends ServiceError {
  final int? attemptsRemaining;
  const InvalidResetCodeError({this.attemptsRemaining});
}

/// Too many consecutive invalid reset code attempts
final class ConsecutiveInvalidResetCodeError extends ServiceError {
  const ConsecutiveInvalidResetCodeError();
}

/// Invalid admin password
final class InvalidAdminPasswordError extends ServiceError {
  const InvalidAdminPasswordError();
}

// ============================================================================
// General Errors
// ============================================================================

/// USP service not initialized or not registered.
///
/// Thrown when `uspServiceProvider` returns null — the app was not properly
/// initialized (e.g. non-Web platform or WASM not loaded). This is a setup
/// error, not a network connectivity issue.
final class ServiceNotInitializedError extends ServiceError {
  final String? message;
  const ServiceNotInitializedError({this.message});

  @override
  String toString() =>
      message != null ? 'Service not initialized: $message' : super.toString();
}

/// Invalid input data
final class InvalidInputError extends ServiceError {
  final String? field;
  final String? message;
  const InvalidInputError({this.field, this.message});

  @override
  String toString() {
    final detail = [
      if (field != null) field,
      if (message != null) message,
    ].join(': ');
    return detail.isNotEmpty ? 'Invalid input: $detail' : super.toString();
  }
}

/// Unexpected error (fallback for unmapped errors)
final class UnexpectedError extends ServiceError {
  final Object? originalError;
  final String? message;
  const UnexpectedError({this.originalError, this.message});

  @override
  String toString() =>
      message != null ? 'Unexpected error: $message' : super.toString();
}

/// Network communication error
final class NetworkError extends ServiceError {
  final String? message;
  const NetworkError({this.message});

  @override
  String toString() =>
      message != null ? 'Network error: $message' : super.toString();
}

/// Storage operation error
final class StorageError extends ServiceError {
  final Object? originalError;
  const StorageError({this.originalError});
}

// ============================================================================
// USP Operation Errors
// ============================================================================

/// USP operation failed completely (all parameters failed)
final class UspCompleteFailureError extends ServiceError {
  final String summary;
  final List<String> failedPaths;

  const UspCompleteFailureError({
    required this.summary,
    required this.failedPaths,
  });

  @override
  String toString() => summary;
}

/// USP operation partially failed (some succeeded, some failed)
final class UspPartialFailureError extends ServiceError {
  final String summary;
  final List<String> successPaths;
  final List<String> failedPaths;

  const UspPartialFailureError({
    required this.summary,
    required this.successPaths,
    required this.failedPaths,
  });

  @override
  String toString() => '(Partial) $summary';
}

// ============================================================================
// Device/Router Errors
// ============================================================================

/// Serial number mismatch between expected and actual router
final class SerialNumberMismatchError extends ServiceError {
  final String expected;
  final String actual;
  const SerialNumberMismatchError(
      {required this.expected, required this.actual});
}

/// Router connectivity error (cannot reach router)
final class ConnectivityError extends ServiceError {
  final String? message;
  const ConnectivityError({this.message});

  @override
  String toString() =>
      message != null ? 'Connectivity error: $message' : super.toString();
}

// ============================================================================
// Side Effect Error (Operation succeeded but device recovery timed out)
// ============================================================================

/// Operation succeeded but triggered a side effect requiring device recovery.
///
/// Unlike other [ServiceError] subtypes, this indicates the operation DID succeed.
/// The device is now recovering (restarting, reconnecting, etc.) and we timed out
/// waiting for it to come back online.
///
/// - [originalResult]: The JNAP result from the operation that triggered the
///   side effect. Contains data like redirection URLs needed after device recovery.
/// - [lastPolledResult]: The last successful poll result before timeout.
///   Useful for diagnosing the device's final known state.
///
/// UI should typically:
/// 1. Inform user the settings were saved
/// 2. Guide user to reconnect to the device
///
/// Example:
/// ```dart
/// try {
///   await service.saveSettings(settings);
/// } on ServiceSideEffectError {
///   showRouterNotFoundAlert(context, ref);
/// }
/// ```
final class ServiceSideEffectError extends ServiceError {
  final Object? originalResult;
  final Object? lastPolledResult;

  const ServiceSideEffectError([this.originalResult, this.lastPolledResult]);
}

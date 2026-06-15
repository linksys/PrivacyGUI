import 'package:privacy_gui/core/usp/models/usp_operation_result.dart'
    show UspErrorDetail;

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
  /// Diagnostic raw fault code (firmware 7xxx/9xxx, WASM 9999, codegen 9998…).
  /// For logging/debugging only — `null` when there is no code.
  final int? code;

  /// Raw technical message (firmware text / WASM string / error identifier).
  ///
  /// Primarily for logging/debugging. For most subtypes the UI derives a
  /// localized message from the subtype itself and ignores [detail]. The
  /// exception is fallback types like [UnexpectedError] that carry no
  /// type-specific semantics — there the UI may surface [detail] directly.
  final String? detail;

  const ServiceError({this.code, this.detail});

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
  const NotAuthenticatedError({super.code, super.detail});
}

/// Session token is invalid or expired
final class InvalidSessionTokenError extends ServiceError {
  const InvalidSessionTokenError({super.code, super.detail});
}

/// Session token has expired and cannot be refreshed
final class SessionTokenExpiredError extends ServiceError {
  const SessionTokenExpiredError({super.code, super.detail});
}

/// Invalid credentials (username/password combination)
final class InvalidCredentialsError extends ServiceError {
  const InvalidCredentialsError({super.code, super.detail});
}

/// Unauthorized access attempt
final class UnauthorizedError extends ServiceError {
  const UnauthorizedError({super.code, super.detail});
}

// ============================================================================
// Resource Errors
// ============================================================================

/// Requested resource not found
final class ResourceNotFoundError extends ServiceError {
  const ResourceNotFoundError({super.code, super.detail});
}

// ============================================================================
// OTP Errors
// ============================================================================

/// Invalid OTP code
final class InvalidOtpError extends ServiceError {
  const InvalidOtpError({super.code, super.detail});
}

/// OTP code has expired
final class ExpiredOtpError extends ServiceError {
  const ExpiredOtpError({super.code, super.detail});
}

// ============================================================================
// Admin Password Errors
// ============================================================================

/// Admin account is locked
final class AdminAccountLockedError extends ServiceError {
  const AdminAccountLockedError({super.code, super.detail});
}

/// Invalid reset code provided
final class InvalidResetCodeError extends ServiceError {
  final int? attemptsRemaining;
  const InvalidResetCodeError(
      {this.attemptsRemaining, super.code, super.detail});
}

/// Too many consecutive invalid reset code attempts
final class ConsecutiveInvalidResetCodeError extends ServiceError {
  const ConsecutiveInvalidResetCodeError({super.code, super.detail});
}

/// Invalid admin password
final class InvalidAdminPasswordError extends ServiceError {
  const InvalidAdminPasswordError({super.code, super.detail});
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
  const ServiceNotInitializedError({super.code, super.detail});

  @override
  String toString() =>
      detail != null ? 'Service not initialized: $detail' : super.toString();
}

/// Invalid input data
final class InvalidInputError extends ServiceError {
  final String? field;
  const InvalidInputError({this.field, super.code, super.detail});

  @override
  String toString() {
    final parts = [
      if (field != null) field,
      if (detail != null) detail,
    ].join(': ');
    return parts.isNotEmpty ? 'Invalid input: $parts' : super.toString();
  }
}

/// Unexpected error (fallback for unmapped errors).
///
/// This is the one type whose semantics the UI cannot derive from the type
/// alone, so [detail] is meant to be surfaced to the user / used by callers
/// (e.g. the local-login flow reads [detail] as an error-code identifier).
final class UnexpectedError extends ServiceError {
  final Object? originalError;
  const UnexpectedError({this.originalError, super.code, super.detail});

  @override
  String toString() =>
      detail != null ? 'Unexpected error: $detail' : super.toString();
}

/// Network communication error
final class NetworkError extends ServiceError {
  const NetworkError({super.code, super.detail});

  @override
  String toString() =>
      detail != null ? 'Network error: $detail' : super.toString();
}

/// Storage operation error
final class StorageError extends ServiceError {
  final Object? originalError;
  const StorageError({this.originalError, super.code, super.detail});
}

// ============================================================================
// USP Operation Errors
// ============================================================================

/// USP operation failed completely (all parameters failed)
final class UspCompleteFailureError extends ServiceError {
  final String summary;

  /// Full per-path diagnostics (path + errorCode + errorMessage), retained so
  /// the UI can later derive a localized message from each [UspErrorDetail].
  final List<UspErrorDetail> failures;

  const UspCompleteFailureError({
    required this.summary,
    required this.failures,
    super.code,
    super.detail,
  });

  /// Backward-compatible: the failed TR-181 paths.
  List<String> get failedPaths => failures.map((f) => f.requestedPath).toList();

  @override
  String toString() => summary;
}

/// USP operation partially failed (some succeeded, some failed)
final class UspPartialFailureError extends ServiceError {
  final String summary;
  final List<String> successPaths;

  /// Full per-path diagnostics for the failed entries.
  final List<UspErrorDetail> failures;

  const UspPartialFailureError({
    required this.summary,
    required this.successPaths,
    required this.failures,
    super.code,
    super.detail,
  });

  /// Backward-compatible: the failed TR-181 paths.
  List<String> get failedPaths => failures.map((f) => f.requestedPath).toList();

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
      {required this.expected, required this.actual, super.code, super.detail});
}

/// Router connectivity error (cannot reach router)
final class ConnectivityError extends ServiceError {
  const ConnectivityError({super.code, super.detail});

  @override
  String toString() =>
      detail != null ? 'Connectivity error: $detail' : super.toString();
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

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
}

// ============================================================================
// Authentication & Session Errors
// ============================================================================

/// Empty email provided
final class EmptyEmailError extends ServiceError {
  const EmptyEmailError();
}

/// Invalid password format or value
final class InvalidPasswordError extends ServiceError {
  const InvalidPasswordError();
}

/// Bad authentication attempt
final class BadAuthenticationError extends ServiceError {
  const BadAuthenticationError();
}

/// Authentication credentials missing
final class AuthenticationMissingError extends ServiceError {
  const AuthenticationMissingError();
}

/// User not authenticated
final class NotAuthenticatedError extends ServiceError {
  const NotAuthenticatedError();
}

/// Session token is invalid or expired
final class InvalidSessionTokenError extends ServiceError {
  const InvalidSessionTokenError();
}

/// No session token found in storage
final class NoSessionTokenError extends ServiceError {
  const NoSessionTokenError();
}

/// Session token has expired and cannot be refreshed
final class SessionTokenExpiredError extends ServiceError {
  const SessionTokenExpiredError();
}

/// Token refresh operation failed
final class TokenRefreshError extends ServiceError {
  final Object? cause;
  const TokenRefreshError({this.cause});
}

/// Multi-factor authentication required
final class MfaRequiredError extends ServiceError {
  const MfaRequiredError();
}

/// Invalid credentials (username/password combination)
final class InvalidCredentialsError extends ServiceError {
  const InvalidCredentialsError();
}

/// Unauthorized access attempt (JNAP: _ErrorUnauthorized)
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

/// Resource exists but not ready
final class ResourceNotReadyError extends ServiceError {
  const ResourceNotReadyError();
}

/// Subject/entity not found
final class SubjectNotFoundError extends ServiceError {
  const SubjectNotFoundError();
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
// User/Account Errors
// ============================================================================

/// Rate limit or threshold exceeded
final class ExceedThresholdError extends ServiceError {
  const ExceedThresholdError();
}

/// Username already exists
final class UsernameExistsError extends ServiceError {
  const UsernameExistsError();
}

/// Invalid phone number format
final class InvalidPhoneError extends ServiceError {
  const InvalidPhoneError();
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

/// Password check is delayed (rate limiting)
final class PasswordCheckDelayedError extends ServiceError {
  const PasswordCheckDelayedError();
}

// ============================================================================
// Network Configuration Errors
// ============================================================================

/// Invalid gateway address
final class InvalidGatewayError extends ServiceError {
  const InvalidGatewayError();
}

/// Invalid IP address
final class InvalidIPAddressError extends ServiceError {
  const InvalidIPAddressError();
}

/// Invalid destination IP address
final class InvalidDestinationIPAddressError extends ServiceError {
  const InvalidDestinationIPAddressError();
}

/// Invalid MAC address
final class InvalidMACAddressError extends ServiceError {
  const InvalidMACAddressError();
}

/// Invalid destination MAC address
final class InvalidDestinationMACAddressError extends ServiceError {
  const InvalidDestinationMACAddressError();
}

/// Invalid primary DNS server
final class InvalidPrimaryDNSServerError extends ServiceError {
  const InvalidPrimaryDNSServerError();
}

/// Invalid secondary DNS server
final class InvalidSecondaryDNSServerError extends ServiceError {
  const InvalidSecondaryDNSServerError();
}

/// Invalid tertiary DNS server
final class InvalidTertiaryDNSServerError extends ServiceError {
  const InvalidTertiaryDNSServerError();
}

/// Invalid server address
final class InvalidServerError extends ServiceError {
  const InvalidServerError();
}

/// Missing destination in configuration
final class MissingDestinationError extends ServiceError {
  const MissingDestinationError();
}

/// Rules overlap conflict
final class RuleOverlapError extends ServiceError {
  const RuleOverlapError();
}

/// Guest SSID conflict
final class GuestSSIDConflictError extends ServiceError {
  const GuestSSIDConflictError();
}

// ============================================================================
// VPN Errors
// ============================================================================

/// VPN is not connected
final class VPNNotConnectedError extends ServiceError {
  const VPNNotConnectedError();
}

/// VPN user already exists
final class VPNUserAlreadyExistsError extends ServiceError {
  const VPNUserAlreadyExistsError();
}

/// VPN user not found
final class VPNUserNotFoundError extends ServiceError {
  const VPNUserNotFoundError();
}

// ============================================================================
// General Errors
// ============================================================================

/// Invalid input data
final class InvalidInputError extends ServiceError {
  final String? field;
  final String? message;
  const InvalidInputError({this.field, this.message});
}

/// Unexpected error (fallback for unmapped errors)
final class UnexpectedError extends ServiceError {
  final Object? originalError;
  final String? message;
  const UnexpectedError({this.originalError, this.message});
}

/// Network communication error
final class NetworkError extends ServiceError {
  final String? message;
  const NetworkError({this.message});
}

/// Storage operation error
final class StorageError extends ServiceError {
  final Object? originalError;
  const StorageError({this.originalError});
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
}

import 'dart:convert';

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Centralized JNAP error to ServiceError mapper.
///
/// All Services should use this to convert JNAPError to ServiceError.
/// This ensures consistent error handling across the application.
///
/// When JNAP is replaced with a new data system, only this file needs modification.
///
/// Example usage:
/// ```dart
/// try {
///   await _routerRepository.send(...);
/// } on JNAPError catch (e) {
///   throw mapJnapErrorToServiceError(e);
/// }
/// ```
ServiceError mapJnapErrorToServiceError(JNAPError error) {
  return switch (error.result) {
    // Authentication & Session Errors
    '_ErrorUnauthorized' => const UnauthorizedError(),
    'ErrorInvalidAdminPassword' => const InvalidAdminPasswordError(),

    // Admin Password & Reset Code Errors
    'ErrorAdminAccountLocked' => const AdminAccountLockedError(),
    'ErrorInvalidResetCode' => InvalidResetCodeError(
        attemptsRemaining: _parseAttemptsRemaining(error),
      ),
    'ErrorConsecutiveInvalidResetCodeEntered' =>
      const ConsecutiveInvalidResetCodeError(),
    'ErrorPasswordCheckDelayed' => const PasswordCheckDelayedError(),

    // Network Configuration Errors
    'ErrorInvalidGateway' => const InvalidGatewayError(),
    'ErrorInvalidIPAddress' => const InvalidIPAddressError(),
    'ErrorInvalidDestinationIPAddress' =>
      const InvalidDestinationIPAddressError(),
    'ErrorInvalidMACAddress' => const InvalidMACAddressError(),
    'ErrorInvalidDestinationMACAddress' =>
      const InvalidDestinationMACAddressError(),
    'ErrorInvalidPrimaryDNSServer' => const InvalidPrimaryDNSServerError(),
    'ErrorInvalidSecondaryDNSServer' => const InvalidSecondaryDNSServerError(),
    'ErrorInvalidTertiaryDNSServer' => const InvalidTertiaryDNSServerError(),
    'ErrorInvalidServer' => const InvalidServerError(),
    'ErrorMissingDestination' => const MissingDestinationError(),
    'ErrorRulesOverlap' => const RuleOverlapError(),
    'ErrorGuestSSIDConflict' => const GuestSSIDConflictError(),

    // VPN Errors
    'ErrorVPNNotConnected' => const VPNNotConnectedError(),
    'ErrorVPNUserAlreadyExists' => const VPNUserAlreadyExistsError(),
    'ErrorVPNUserNotFound' => const VPNUserNotFoundError(),

    // Input Validation Errors
    '_ErrorInvalidInput' => InvalidInputError(
        message: _parseErrorMessage(error),
      ),

    // Fallback for unmapped errors
    _ => UnexpectedError(originalError: error, message: error.result),
  };
}

/// Parses attemptsRemaining from JNAPError payload.
///
/// Used for errors like ErrorInvalidResetCode that include
/// remaining attempt count in the error response.
int? _parseAttemptsRemaining(JNAPError error) {
  if (error.error == null) return null;
  try {
    final errorOutput = jsonDecode(error.error!) as Map<String, dynamic>;
    return errorOutput['attemptsRemaining'] as int?;
  } catch (_) {
    return null;
  }
}

/// Parses error message from JNAPError payload.
String? _parseErrorMessage(JNAPError error) {
  if (error.error == null) return null;
  try {
    final errorOutput = jsonDecode(error.error!) as Map<String, dynamic>;
    return errorOutput['message'] as String?;
  } catch (_) {
    return error.error;
  }
}

import 'package:flutter/material.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Translates a given error code into a human-readable, localized error message.
///
/// This function uses a `switch` statement to map predefined error codes to
/// corresponding localized strings. If the error code is not recognized, it logs
/// the unknown code and returns a generic error message.
///
/// [context] The `BuildContext` used to access localized strings.
///
/// [code] The error code string to be translated. If `null` or empty,
/// the function will return `null`.
///
/// [generalErrorMessage] An optional fallback message to display for
/// unrecognized error codes. If not provided, a default "unknown error"
/// message is used.
///
/// Returns the localized error message as a `String?`, or `null` if the
/// input code is null or empty.
String? errorCodeHelper(BuildContext context, String? code,
    [String? generalErrorMessage]) {
  String unknownHandle(String code) {
    logger.d('Unknown error: $code');
    return generalErrorMessage ?? loc(context).unknownErrorCode(code);
  }

  if (code == null) {
    return null;
  }
  return switch (code) {
    '' => null,
    errorUsernameExists => loc(context).errorUsernameAlreadyExist,
    errorEmptyEmail => loc(context).errorEnterAValidEmailFormat,
    errorInvalidPassword => loc(context).errorIncorrectPassword,
    errorInvalidCredentials => loc(context).errorIncorrectPassword,
    errorResourceNotFound => loc(context).errorEmailAddressNotFound,
    errorInvalidOtp => loc(context).errorInvalidOtp,
    errorExpiredOtp => loc(context).errorExpiredOtp,
    errorExceedThreshold => loc(context).errorOtpExceedsThreshold,
    errorInvalidPhone => loc(context).errorInvalidPhoneNumber,
    errorJNAPUnauthorized => loc(context).errorIncorrectPassword,
    errorAdminAccountLocked => loc(context).localLoginTooManyAttemptsTitle,
    errorInvalidDestinationMACAddress =>
      loc(context).invalidDestinationMacAddress,
    errorInvalidDestinationIpAddress =>
      loc(context).invalidDestinationIpAddress,
    errorInvalidGateway => loc(context).invalidGatewayIpAddress,
    errorInvalidIPAddress => loc(context).invalidIpAddress,
    errorInvalidPrimaryDNSServer => loc(context).invalidDns,
    errorInvalidSecondaryDNSServer => loc(context).invalidDns,
    errorInvalidTertiaryDNSServer => loc(context).invalidDns,
    errorInvalidMACAddress => loc(context).invalidMACAddress,
    errorInvalidInput => loc(context).invalidInput,
    errorInvalidServer => loc(context).errorInvalidServer,
    errorMissingDestination => loc(context).invalidDestinationIpAddress,
    errorRuleOverlap => loc(context).rulesOverlapError,
    errorGuestSSIDConflict => loc(context).errorGuestSSIDConflict,
    errorVPNNotConnected => loc(context).vpnErrorVPNNotConnected,
    errorVPNUserAlreadyExists => loc(context).vpnErrorVPNUserAlreadyExists,
    errorVPNUserNotFound => loc(context).vpnErrorVPNUserNotFound,
    _ => unknownHandle(code),
  };
}

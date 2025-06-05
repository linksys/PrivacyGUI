import 'package:flutter/material.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/utils/logger.dart';

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

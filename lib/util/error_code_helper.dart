import 'package:flutter/material.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/utils/logger.dart';

String? errorCodeHelper(BuildContext context, String? code) {
  String unknownHandle(String code) {
    logger.d('Unknown error: $code');
    return loc(context).unknownErrorCode(code);
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
    errorMissingDestination => loc(context).invalidDestinationIpAddress,
    _ => unknownHandle(code),
  };
}

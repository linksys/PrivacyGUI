import 'package:flutter/material.dart';
import 'package:linksys_app/constants/error_code.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/utils/logger.dart';

String? generalErrorCodeHandler(BuildContext context, String code) {
  switch (code) {
    case '':
      return null;
    case errorUsernameExists:
      return loc(context).errorUsernameAlreadyExist;
    case errorEmptyEmail:
      return loc(context).errorEnterAValidEmailFormat;
    case errorInvalidPassword:
      return loc(context).errorIncorrectPassword;
    case errorInvalidCredentials:
      return loc(context).errorIncorrectPassword;
    case errorResourceNotFound:
      return loc(context).errorEmailAddressNotFound;
    case errorInvalidOtp:
      return loc(context).errorInvalidOtp;
    case errorExpiredOtp:
      return loc(context).errorExpiredOtp;
    case errorExceedThreshold:
      return loc(context).errorOtpExceedsThreshold;
    case errorInvalidPhone:
      return loc(context).errorInvalidPhoneNumber;
    case errorJNAPUnauthorized:
      return loc(context).errorIncorrectPassword;
    case errorAdminAccountLocked:
      return loc(context).localLoginTooManyAttemptsTitle;
    default:
      logger.e('Unhandled Error: $code');
      return loc(context).unknownErrorCode(code);
  }
}

import 'package:flutter/material.dart';
import 'package:linksys_app/constants/error_code.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/core/utils/logger.dart';

String? generalErrorCodeHandler(BuildContext context, String code) {
  switch (code) {
    case '':
      return null;
    case errorUsernameExists:
      return getAppLocalizations(context).error_username_already_exist;
    case errorEmptyEmail:
      return getAppLocalizations(context).error_enter_a_valid_email_format;
    case errorInvalidPassword:
      return getAppLocalizations(context).error_incorrect_password;
    case errorInvalidCredentials:
      return getAppLocalizations(context).error_incorrect_password;
    case errorResourceNotFound:
      return getAppLocalizations(context).error_email_address_not_fount;
    case errorInvalidOtp:
      return getAppLocalizations(context).error_invalid_otp;
    case errorExpiredOtp:
      return getAppLocalizations(context).error_expired_otp;
    case errorExceedThreshold:
      return getAppLocalizations(context).error_otp_exceeds_threshold;
    case errorInvalidPhone:
      return getAppLocalizations(context).error_invalid_phone_number;
    case errorJNAPUnauthorized:
      return getAppLocalizations(context).error_incorrect_password;
    case errorAdminAccountLocked:
      return getAppLocalizations(context).error_local_access_locked;
    default:
      logger.e('Unhandled Error: $code');
      return getAppLocalizations(context).unknown_error_code(code);
  }
}

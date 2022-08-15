import 'package:linksys_moab/bloc/auth/state.dart';

abstract class AuthEvent {}

class InitAuth extends AuthEvent {}

class OnCloudLogin extends AuthEvent {
  OnCloudLogin({required this.accountInfo, required this.vToken});

  final AccountInfo accountInfo;
  final String vToken;
}

class OnLocalLogin extends AuthEvent {
  OnLocalLogin({required this.localLoginInfo});

  final LocalLoginInfo localLoginInfo;
}

class OnCreateAccount extends AuthEvent {
  OnCreateAccount({required this.accountInfo, required this.vToken});

  final AccountInfo accountInfo;
  final String vToken;
}

class Unauthorized extends AuthEvent {}

class Authorized extends AuthEvent {
  Authorized(
      {required this.accountInfo,
      required this.publicKey,
      required this.privateKey,
      this.isDuringSetup = false});

  final AccountInfo accountInfo;
  final String publicKey;
  final String privateKey;
  final bool isDuringSetup;
}

class RequireOtpCode extends AuthEvent {
  RequireOtpCode({required this.otpInfo});

  final OtpInfo otpInfo;
}

class SetOtpInfo extends AuthEvent {
  SetOtpInfo({required this.otpInfo});

  final List<OtpInfo> otpInfo;
}

class SetLoginType extends AuthEvent {
  SetLoginType({required this.loginType});

  final LoginType loginType;
}

class SetCloudPassword extends AuthEvent {
  SetCloudPassword({required this.password});

  final String password;
}

class CloudLogin extends AuthEvent {}

class LocalLogin extends AuthEvent {}

class Logout extends AuthEvent {
  Logout({this.reason = 0});

  final int reason;
}

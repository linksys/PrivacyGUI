import 'package:linksys_moab/bloc/auth/state.dart';
import 'package:linksys_moab/network/http/model/cloud_communication_method.dart';
import 'package:linksys_moab/repository/model/cloud_session_model.dart';

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
  Authorized({this.isDuringSetup = false, this.isCloud = false});

  final bool isDuringSetup; // TODO seems this is not used anymore
  final bool isCloud;
}

class SetLoginType extends AuthEvent {
  SetLoginType({required this.loginType});

  final AuthenticationType loginType;
}

class SetCloudPassword extends AuthEvent {
  SetCloudPassword({required this.password});

  final String password;
}

class SetEnableBiometrics extends AuthEvent {
  SetEnableBiometrics({required this.enableBiometrics});

  final bool enableBiometrics;
}

class OnRequestSession extends AuthEvent {}

class CloudLogin extends AuthEvent {
  CloudLogin({required this.sessionToken});
  final SessionToken sessionToken;
}

class LocalLogin extends AuthEvent {
  LocalLogin(this.password);
  final String password;
}

class Logout extends AuthEvent {
  Logout({this.reason = 0});

  final int reason;
}

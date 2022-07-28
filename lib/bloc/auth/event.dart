
import 'package:moab_poc/bloc/auth/state.dart';

abstract class AuthEvent {}

class InitAuth extends AuthEvent {}

class OnLogin extends AuthEvent {}

class OnCreateAccount extends AuthEvent {}

class Unauthorized extends AuthEvent {}

class Authorized extends AuthEvent {}

class RequireOtpCode extends AuthEvent{
  RequireOtpCode({required this.otpInfo});

  final OtpInfo otpInfo;
}

class SetCloudPassword extends AuthEvent{
  SetCloudPassword({required this.password});

  final String password;
}
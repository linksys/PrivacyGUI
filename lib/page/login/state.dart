import 'package:flutter/material.dart';
import 'package:moab_poc/page/login/bloc.dart';
import 'package:moab_poc/page/poc/login/state.dart';
import 'package:moab_poc/repository/model/dummy_model.dart';

@immutable
abstract class LoginState{
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial(): super();
}

class ForgotEmail extends LoginState {
  const ForgotEmail(): super();
}

class LocalLogin extends LoginState {
  const LocalLogin(): super();
}

class ChoosePasswordLessMethod extends LoginState {
  const ChoosePasswordLessMethod(List<DummyModel> methods): super();
}

class WaitForOTP extends LoginState {
  const WaitForOTP(OtpMethod method, String target): super();
}
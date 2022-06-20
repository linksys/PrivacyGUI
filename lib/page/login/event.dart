import 'package:flutter/material.dart';

@immutable
abstract class LoginEvent {
  const LoginEvent();
}

class Initial extends LoginEvent {}
class GoForgotEmail extends LoginEvent {}
class GoLocalLogin extends LoginEvent {}
class TestUserName extends LoginEvent {
  const TestUserName(this.username);
  final String username;
}
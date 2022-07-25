
abstract class AuthEvent {}

class InitAuth extends AuthEvent {}

class OnLogin extends AuthEvent {}

class OnCreateAccount extends AuthEvent {}

class Unauthorized extends AuthEvent {}

class Authorized extends AuthEvent {}

class SetEmail extends AuthEvent{
  SetEmail({required this.email});

  final String email;
}
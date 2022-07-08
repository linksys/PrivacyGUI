
abstract class AuthEvent {}

class InitAuth extends AuthEvent {}

class SetEmail extends AuthEvent{
  SetEmail({required this.email});

  final String email;
}
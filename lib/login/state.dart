import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  const LoginState._({
    this.isLoggedIn = false,
  });

  final bool isLoggedIn;

  const LoginState.unauthenticated() : this._(isLoggedIn: false);

  const LoginState.authenticated() : this._(isLoggedIn: true);

  @override
  List<Object> get props => [isLoggedIn];
}

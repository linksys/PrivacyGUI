import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  const LoginState._(
      {this.isLoggedIn = false, this.username = '', this.password = ''});

  final bool isLoggedIn;
  final String username;
  final String password;

  const LoginState.unauthenticated() : this._(isLoggedIn: false);

  const LoginState.authenticated() : this._(isLoggedIn: true);

  const LoginState.updateUsername(String username) : this._(username: username);

  const LoginState.updatePassword(String password) : this._(password: password);

  @override
  List<Object> get props => [isLoggedIn, username, password];
}

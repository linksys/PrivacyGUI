import 'package:equatable/equatable.dart';

///
/// {
///   "token": "string",
///   "method": "EMAIL",
///   "target": "+886900000000"
/// }
///
class AuthChallengeMethod extends Equatable {
  const AuthChallengeMethod({
    required this.token,
    required this.method,
    required this.target,
  });

  factory AuthChallengeMethod.fromJson(Map<String, dynamic> json) {
    return AuthChallengeMethod(
      token: json['token'],
      method: json['method'],
      target: json['target'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'token': token,
      'method': method,
      'target': target,
    };

    return json;
  }

  final String token;
  final String method;
  final String target;

  @override
  List<Object?> get props => [method, target, token];
}

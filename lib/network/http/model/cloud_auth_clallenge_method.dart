import 'package:equatable/equatable.dart';

abstract class BaseAuthChallenge extends Equatable {
  const BaseAuthChallenge({
    required this.token,
  });
  Map<String, dynamic> toJson();
  final String token;
}

///
/// {
///   "token": "string",
///   "method": "EMAIL",
///   "target": "+886900000000"
/// }
///
class AuthChallengeMethod extends BaseAuthChallenge {
  const AuthChallengeMethod({
    required super.token,
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

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'token': token,
      'method': method,
      'target': target,
    };

    return json;
  }

  final String method;
  final String target;

  @override
  List<Object?> get props => [method, target, token];
}

///
/// {
///   "token": "string",
///   "methodId": "a3e8950a-xxxx-4601-xxxx-b8428d542128",
/// }
///
class AuthChallengeMethodId extends BaseAuthChallenge {
  const AuthChallengeMethodId({
    required super.token,
    required this.commMethodId,
  });

  factory AuthChallengeMethodId.fromJson(Map<String, dynamic> json) {
    return AuthChallengeMethodId(
      token: json['token'],
      commMethodId: json['commMethodId'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'token': token,
      'commMethodId': commMethodId,
    };

    return json;
  }

  final String commMethodId;

  @override
  List<Object?> get props => [commMethodId, token];
}
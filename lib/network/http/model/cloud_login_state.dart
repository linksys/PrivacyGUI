import 'package:equatable/equatable.dart';

///
/// {
///   "state": "REQUIRED_2SV",
///   "data": {
///     "token": "string",
///     "authenticationMode": "PASSWORDLESS"
///   }
/// }
///
class CloudLoginState extends Equatable {
  const CloudLoginState({
    required this.state,
    required this.data,
  });

  factory CloudLoginState.fromJson(Map<String, dynamic> json) {
    return CloudLoginState(
      state: json['state'],
      data: CloudLoginPrepareData.fromJson(json),
    );
  }

  final String state;
  final CloudLoginPrepareData data;

  @override
  List<Object?> get props => [state, data];
}

///   {
///     "token": "string",
///     "authenticationMode": "PASSWORDLESS"
///   }
class CloudLoginPrepareData extends Equatable {
  const CloudLoginPrepareData({
    required this.token,
    required this.authenticationMode,
  });

  factory CloudLoginPrepareData.fromJson(Map<String, dynamic> json) {
    return CloudLoginPrepareData(
      token: json['token'],
      authenticationMode: json['authenticationMode'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'authenticationMode': authenticationMode,
    };
  }

  final String token;
  final String authenticationMode;


  @override
  List<Object?> get props =>
      [token, authenticationMode];
}

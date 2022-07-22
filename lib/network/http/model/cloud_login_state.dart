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
    this.data,
  });

  factory CloudLoginState.fromJson(Map<String, dynamic> json) {
    return CloudLoginState(
      state: json['state'],
      data: json['data'] == null ? null : CloudLoginStateData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      'state': state,
    };
    if (data != null) {
      result.addAll({'data': data!.toJson()});
    }
    return result;
  }

  final String state;
  final CloudLoginStateData? data;

  @override
  List<Object?> get props => [state, data];
}

///   {
///     "token": "string",
///     "authenticationMode": "PASSWORDLESS"
///   }
class CloudLoginStateData extends Equatable {
  const CloudLoginStateData({
    required this.token,
    required this.authenticationMode,
  });

  factory CloudLoginStateData.fromJson(Map<String, dynamic> json) {
    return CloudLoginStateData(
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
  List<Object?> get props => [token, authenticationMode];
}

import 'package:equatable/equatable.dart';

class SessionToken extends Equatable {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;

  const SessionToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
  });

  @override
  List<Object?> get props => [accessToken, tokenType, expiresIn, refreshToken];

  factory SessionToken.fromJson(Map<String, dynamic> json) {
    return SessionToken(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'refresh_token': refreshToken,
    };
  }
}

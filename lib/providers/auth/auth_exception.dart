// ignore_for_file: public_member_api_docs, sort_constructors_first

abstract class AuthException {
  static const codeAuthExceptionNoSessionTokenFound = -1;

  final String message;
  const AuthException({
    required this.message,
  });
}

class NoSessionTokenFoundException extends AuthException {
  NoSessionTokenFoundException() : super(message: 'no session token found');
}

class NeedToRefreshTokenException extends AuthException {
  final String refreshToken;
  NeedToRefreshTokenException(this.refreshToken)
      : super(message: 'token expired! can be refresh');
}

class SessionTokenExpiredException extends AuthException {
  SessionTokenExpiredException()
      : super(message: 'token expired! logging out!');
}

class CloudNetworkNotFoundException extends AuthException {
  CloudNetworkNotFoundException() : super(message: 'cloud network not found!');
}

class CloudAuthInvalidException extends AuthException {
  CloudAuthInvalidException() : super(message: 'cloud auth invalid!');
}

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

class SessionTokenExpiredException extends AuthException {
  SessionTokenExpiredException()
      : super(message: 'token expired! logging out!');
}

/// Ends work that belonged to a login once that login has ended (#1904):
/// a [RouterRepository.scheduledCommand] loop given the login's
/// `AuthNotifier.logoutGeneration`, and the flow it belongs to.
///
/// It lives here, with the other login exceptions, so that a page can catch
/// it without importing the data layer (constitution 1.2).
class LoggedOutException implements Exception {
  const LoggedOutException();

  @override
  String toString() =>
      'LoggedOutException: the login this work belonged to has ended';
}

/// How a package widget's `cgi_call` action went (constitution 3.3.6).
sealed class CgiCallResult {
  const CgiCallResult();
}

/// The router answered 200.
final class CgiCallSuccess extends CgiCallResult {
  const CgiCallSuccess();
}

/// Nothing was sent: the URL is not a local CGI path. The card shows nothing.
final class CgiCallSkipped extends CgiCallResult {
  const CgiCallSkipped();
}

/// The router answered another status, or the request failed.
final class CgiCallFailure extends CgiCallResult {
  const CgiCallFailure({this.statusCode});

  /// The status the router answered; `null` when there was no answer.
  final int? statusCode;
}

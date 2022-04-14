enum ReplyStatus {
  ok,
  forbidden,
  timeout,
  error,
  handshakeError,
  notFound,
  unknown
}

abstract class ReplyBase {
  ReplyBase(this.status);

  final ReplyStatus status;
}

/// The bridge client's error types, shared by both of its implementations.
///
/// One file because `usp_bridge_client.dart` picks an implementation by
/// conditional export, and each implementation used to declare these itself. Two
/// copies of a class whose behaviour is a getter — `isDeviceOffline`,
/// `isNotFound` — is two definitions of what a status code means, free to drift
/// apart with nothing to notice: the VM stub only ever runs in tests, and the web
/// copy only in a browser. Both implementations export this file, so every
/// caller still imports them from `usp_bridge_client.dart`.
library;

/// Exception thrown when session expires and cannot be recovered.
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException(this.message);

  @override
  String toString() => 'SessionExpiredException: $message';
}

/// An SSE stream that Guardian or the bridge refused to open.
///
/// Carries the status because **400 means something different from every other
/// code**: Guardian rejects a stream against an offline device with a 400, before it
/// publishes anything, and keeps doing so until the device comes back. Every other
/// failure is the connection between this browser and the proxy. #205 Item 8 asks the
/// UI to tell those apart, and a plain string error — which is what this path added
/// until #1577 — cannot.
class SseStreamException implements Exception {
  final int statusCode;
  final String statusText;

  SseStreamException(this.statusCode, this.statusText);

  /// Whether the device is not currently reachable by the proxy.
  ///
  /// Retrying is pointless until it is back, which is the distinction the banner
  /// renders: "wait" versus "something between you and the proxy broke".
  bool get isDeviceOffline => statusCode == 400;

  @override
  String toString() => 'SseStreamException($statusCode $statusText)';
}

/// A bridge read that answered with something other than a 2xx.
///
/// Carries the status code because the callers need it: a `404` on a single
/// notification means "no longer available" and is ordinary, while anything else
/// is a fault. Mapping to `ServiceError` happens in the service layer, per
/// constitution Article XIII — this type is the transport's own vocabulary.
class BridgeReadException implements Exception {
  final int statusCode;

  /// Which read produced it, for the log line. Not user-visible.
  final String label;

  BridgeReadException(this.statusCode, this.label);

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'BridgeReadException($label, HTTP $statusCode)';
}

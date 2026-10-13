/// SSE connection lifecycle states.
enum SseConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,

  /// Reconnection gave up after `SseConnectionManager._maxRetries` consecutive
  /// failures. Call `SseConnectionManager.tryReconnect` to retry.
  suspended,
}

/// Why the SSE stream is not currently carrying traffic.
///
/// #205 Item 8, and it exists because two situations that need opposite responses
/// arrive through the same failed connect. Guardian rejects a stream against an
/// **offline device** with a 400, before it publishes anything, and keeps doing so
/// until the device comes back — so the answer is "wait". Anything else is the path
/// between this browser and the proxy — so the answer is "try again", and a support
/// engineer reading a red banner could not previously tell which they were looking at.
///
/// Not folded into [SseConnectionState], deliberately: the state says *what the
/// connection is doing* and every value of it is reachable in both situations. Two
/// orthogonal facts on one enum would be a product of two enums written out by hand.
enum SseDisconnectCause {
  /// No failure recorded, or the last attempt succeeded.
  none,

  /// The proxy says the device is not reachable (400). Retrying does nothing until
  /// it is back.
  deviceOffline,

  /// Anything else: a 5xx, a network error, a closed stream. Retrying may work.
  transportFailure,
}

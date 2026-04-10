import 'usp_client.dart';

/// Stub implementation of [UspBridgeClient] for non-Web platforms (Dart VM / tests).
///
/// Selected by conditional export when `dart.library.js_interop` is unavailable.
/// All methods throw [UnsupportedError] since SSE/bridge functionality
/// requires the browser Fetch API.
class UspBridgeClient {
  UspBridgeClient(UspClient usp);

  Future<Map<String, dynamic>> health() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Stream<SseEvent> notifications() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, String>> notificationsProbe() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> subscribe({
    required String subscriptionId,
    required String path,
    required int notifType,
  }) =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> unsubscribe({
    required String subscriptionId,
  }) =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> turboStart() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> turboHeartbeat() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> turboStatus() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> turboRelease() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  /// Synchronously abort the active SSE stream. No-op on non-Web platforms.
  void abortSse() {}

  /// Abort SSE from a previous hot restart session. No-op on non-Web platforms.
  static void abortPreviousSession() {}
}

/// A parsed Server-Sent Event.
class SseEvent {
  final String event;
  final String data;
  final String? id;

  SseEvent({required this.event, required this.data, this.id});

  @override
  String toString() => 'SseEvent(event=$event, data=$data, id=$id)';
}

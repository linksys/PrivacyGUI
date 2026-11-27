import 'bridge_endpoints.dart';
import 'session_auth_gate.dart';
import 'usp_client.dart';

export 'session_auth_gate.dart' show RequestKind;
export 'sse_operation_strategy.dart' show AuthBehavior;
export 'usp_bridge_client_errors.dart';

/// Stub implementation of [UspBridgeClient] for non-Web platforms (Dart VM / tests).
///
/// Selected by conditional export when `dart.library.js_interop` is unavailable.
/// All methods throw [UnsupportedError] since SSE/bridge functionality
/// requires the browser Fetch API.
class UspBridgeClient {
  UspBridgeClient(
    UspClient usp, {
    BridgeEndpoints? endpoints,
    String? baseUrl,
    String? authToken,
    String? clientTypeId,
    required SessionAuthGate gate,
    RemoteReads? remoteReads,
  });

  Future<Map<String, dynamic>> health({
    RequestKind kind = RequestKind.normal,
  }) =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Stream<SseEvent> notifications() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, String>> notificationsProbe() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> uspState() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> notificationsHistory() =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<Map<String, dynamic>> notification(String msgId) =>
      throw UnsupportedError('UspBridgeClient is only available on Web');

  Future<List<Object?>> results(String commandKey) =>
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

  Future<List<String>> listSubscriptions() =>
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

import 'dart:async';
import 'dart:typed_data';

import 'package:privacy_gui/core/usp/models/usp_ws_message.dart';
import 'package:privacy_gui/core/usp/models/ws_connection_state.dart';

/// Stub implementation for non-Web platforms.
/// WebSocket client is only available on Web via WASM.
class UspWsClientWrapper {
  UspWsClientWrapper._();

  static Future<UspWsClientWrapper> connect(
    String url, {
    String? subprotocol,
  }) async {
    throw UnsupportedError('WebSocket client is only available on Web');
  }

  WsConnectionState get state => WsConnectionState.closed;

  Stream<UspWsMessage> get onMessage => const Stream.empty();
  Stream<WsConnectionState> get onStateChange => const Stream.empty();

  Future<void> sendRecord(Uint8List data) async {
    throw UnsupportedError('WebSocket client is only available on Web');
  }

  Future<void> sendWebSocketConnect({
    required String fromId,
    required String toId,
  }) async {
    throw UnsupportedError('WebSocket client is only available on Web');
  }

  Future<void> sendGetRecord({
    required String path,
    required String fromId,
    required String toId,
  }) async {
    throw UnsupportedError('WebSocket client is only available on Web');
  }

  Future<void> sendOperateRecord({
    required String command,
    required Map<String, String> inputArgs,
    required String fromId,
    required String toId,
  }) async {
    throw UnsupportedError('WebSocket client is only available on Web');
  }

  void close() {}

  void dispose() {}
}

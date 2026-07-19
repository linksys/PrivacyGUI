@JS()
library usp_ws_client;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:privacy_gui/core/usp/models/usp_ws_message.dart';
import 'package:privacy_gui/core/usp/models/ws_connection_state.dart';
import 'package:privacy_gui/core/utils/logger.dart';

const _tag = '[USPWsClient]:';

// -----------------------------------------------------------------------------
// JS Interop Bindings for UspWsClient
// -----------------------------------------------------------------------------

@JS('UspWsClient')
extension type UspWsClientJS._(JSObject _) implements JSObject {
  @JS('connect')
  external static JSPromise<JSAny?> connect_(
      JSString url, JSString? subprotocol);

  external void close();
  external void free();

  @JS('sendRecord')
  external JSPromise<JSAny?> sendRecord_(JSUint8Array bytes);

  @JS('onRecord')
  external void onRecord_(JSFunction cb);

  @JS('onStateChange')
  external void onStateChange_(JSFunction cb);
}

// -----------------------------------------------------------------------------
// JS Interop Bindings for Record Builders
// -----------------------------------------------------------------------------

@JS('buildGetRecord')
external JSUint8Array buildGetRecordJS(
    JSString path, JSString fromId, JSString toId);

@JS('buildOperateRecord')
external JSUint8Array buildOperateRecordJS(
    JSString command, JSAny inputArgs, JSString fromId, JSString toId);

@JS('buildWebSocketConnect')
external JSUint8Array buildWebSocketConnectJS(JSString fromId, JSString toId);

@JS('decodeRecord')
external JSAny decodeRecordJS(JSUint8Array data);

// Native JS helpers copy Wasm-backed bytes before a Wasm memory growth can
// detach their ArrayBuffer while Dart hands them back to JavaScript.
@JS('sendWebSocketConnectNative')
external JSPromise<JSAny?> _sendWebSocketConnectNative(
    UspWsClientJS wsClient, JSString fromId, JSString toId);

@JS('sendOperateRecordNative')
external JSPromise<JSAny?> _sendOperateRecordNative(UspWsClientJS wsClient,
    JSString command, JSAny inputArgs, JSString fromId, JSString toId);

// -----------------------------------------------------------------------------
// Dart Wrapper
// -----------------------------------------------------------------------------

/// Dart-friendly wrapper around the WASM UspWsClient for WebSocket communication.
///
/// ## Usage
/// ```dart
/// final client = await UspWsClientWrapper.connect('wss://192.168.1.1/usp-ws');
///
/// client.onMessage.listen((msg) {
///   print('Received: ${msg.msgType}');
/// });
///
/// client.onStateChange.listen((state) {
///   if (state == WsConnectionState.closed) {
///     print('Connection closed');
///   }
/// });
///
/// // Send WebSocket handshake (required by TR-369)
/// await client.sendWebSocketConnect(fromId: 'controller::localui', toId: 'os::router');
///
/// // Send an Operate command
/// await client.sendOperateRecord(
///   command: 'Device.LocalAgent.X_LINKSYS_Download()',
///   inputArgs: {'Data': base64Chunk, 'Offset': '0'},
///   fromId: 'controller::localui',
///   toId: 'os::router',
/// );
///
/// client.close();
/// ```
class UspWsClientWrapper {
  UspWsClientWrapper._(this._jsClient) {
    _setupCallbacks();
  }

  final UspWsClientJS _jsClient;
  final StreamController<UspWsMessage> _messageController =
      StreamController<UspWsMessage>.broadcast();
  final StreamController<WsConnectionState> _stateController =
      StreamController<WsConnectionState>.broadcast();
  WsConnectionState _currentState = WsConnectionState.connecting;
  bool _disposed = false;

  /// Current connection state.
  WsConnectionState get state => _currentState;

  /// Stream of parsed USP messages received from the router.
  Stream<UspWsMessage> get onMessage => _messageController.stream;

  /// Stream of connection state changes.
  Stream<WsConnectionState> get onStateChange => _stateController.stream;

  /// Connect to a WebSocket endpoint.
  ///
  /// [url] - WebSocket URL (e.g., "wss://192.168.1.1/usp-ws")
  /// [subprotocol] - WebSocket subprotocol. Defaults to "v1.usp" per TR-369 §6.4.4.
  ///                 OBUSPA destroys connections without this subprotocol.
  static Future<UspWsClientWrapper> connect(
    String url, {
    String subprotocol = 'v1.usp',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    logger.d('$_tag Connecting to $url with subprotocol: $subprotocol');
    try {
      final jsClient = await UspWsClientJS.connect_(
        url.toJS,
        subprotocol.toJS,
      ).toDart.timeout(timeout, onTimeout: () {
        logger.e('$_tag Connection timeout after ${timeout.inSeconds}s');
        throw StateError('WebSocket connection timeout');
      });

      if (jsClient == null) {
        throw StateError('WebSocket connect returned null');
      }

      final wrapper = UspWsClientWrapper._(jsClient as UspWsClientJS);
      // The producer's connect Promise is the readiness contract: it resolves
      // only after the browser upgrade reaches OPEN and rejects failed
      // upgrades. Do not infer readiness from a timer.
      wrapper._currentState = WsConnectionState.open;
      logger.i('$_tag Connected to $url');
      return wrapper;
    } catch (e) {
      logger.e('$_tag Connection failed: $e');
      rethrow;
    }
  }

  void _setupCallbacks() {
    _jsClient.onRecord_(_onRecordCallback.toJS);
    _jsClient.onStateChange_(_onStateCallback.toJS);
  }

  void _onRecordCallback(JSUint8Array bytes) {
    if (_disposed) return;
    try {
      final decoded = decodeRecordJS(bytes);
      final map = decoded.dartify();
      if (map is Map) {
        final message = UspWsMessage.fromJs(Map<String, dynamic>.from(map));
        logger.d('$_tag Received: ${message.msgType} (${message.msgId})');
        _messageController.add(message);
      }
    } catch (e) {
      logger.e('$_tag Failed to decode record: $e');
    }
  }

  void _onStateCallback(JSString state) {
    if (_disposed) return;
    final stateStr = state.toDart;
    final newState = parseWsConnectionState(stateStr);
    if (newState != _currentState) {
      _currentState = newState;
      logger.d('$_tag State changed: $stateStr');
      _stateController.add(newState);
    }
  }

  /// Send raw bytes over the WebSocket.
  Future<void> sendRecord(Uint8List bytes) async {
    if (_disposed) {
      throw StateError('WebSocket client has been disposed');
    }
    if (_currentState != WsConnectionState.open) {
      throw StateError('WebSocket is not open (state: $_currentState)');
    }
    logger.d('$_tag sendRecord: ${bytes.length} bytes');
    await _jsClient.sendRecord_(bytes.toJS).toDart;
  }

  /// Send a WebSocketConnect record (required as first frame per TR-369 §6.4.5).
  Future<void> sendWebSocketConnect({
    required String fromId,
    required String toId,
  }) async {
    logger.d(
        '$_tag [WS-CONNECT] Using native JS helper: fromId=$fromId, toId=$toId');
    // Use native JS helper to bypass Dart interop issues
    await _sendWebSocketConnectNative(_jsClient, fromId.toJS, toId.toJS).toDart;
    logger.d('$_tag [WS-CONNECT] Native helper completed');
  }

  /// Send a Get record for a single parameter path.
  Future<void> sendGetRecord({
    required String path,
    required String fromId,
    required String toId,
  }) async {
    logger.d('$_tag Sending Get: $path');
    final bytes = buildGetRecordJS(path.toJS, fromId.toJS, toId.toJS);
    await _jsClient.sendRecord_(bytes).toDart;
  }

  /// Send an Operate record.
  Future<void> sendOperateRecord({
    required String command,
    required Map<String, String> inputArgs,
    required String fromId,
    required String toId,
  }) async {
    logger.d('$_tag [OPERATE] Using native JS helper: command=$command');
    // Use native JS helper to bypass Dart interop issues
    final jsInputArgs = inputArgs.jsify()!;
    await _sendOperateRecordNative(
      _jsClient,
      command.toJS,
      jsInputArgs,
      fromId.toJS,
      toId.toJS,
    ).toDart;
    logger.d('$_tag [OPERATE] Native helper completed');
  }

  /// Close the WebSocket connection gracefully.
  void close() {
    if (_disposed) return;
    logger.d('$_tag Closing connection');
    _jsClient.close();
    _currentState = WsConnectionState.closed;
  }

  /// Dispose resources. After calling this, the instance cannot be reused.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    close();
    _messageController.close();
    _stateController.close();
    _jsClient.free();
    logger.d('$_tag Disposed');
  }
}

// -----------------------------------------------------------------------------
// Standalone Record Builder Functions (for use without a client instance)
// -----------------------------------------------------------------------------

/// Build a USP Get record for WebSocket transmission.
Uint8List buildGetRecord({
  required String path,
  required String fromId,
  required String toId,
}) {
  return buildGetRecordJS(path.toJS, fromId.toJS, toId.toJS).toDart;
}

/// Build a USP Operate record for WebSocket transmission.
Uint8List buildOperateRecord({
  required String command,
  required Map<String, String> inputArgs,
  required String fromId,
  required String toId,
}) {
  return buildOperateRecordJS(
    command.toJS,
    inputArgs.jsify()!,
    fromId.toJS,
    toId.toJS,
  ).toDart;
}

/// Build a WebSocketConnect handshake record (TR-369 §6.4.5).
Uint8List buildWebSocketConnectRecord({
  required String fromId,
  required String toId,
}) {
  return buildWebSocketConnectJS(fromId.toJS, toId.toJS).toDart;
}

/// Decode a raw USP record received over WebSocket.
UspWsMessage decodeRecord(Uint8List data) {
  final decoded = decodeRecordJS(data.toJS);
  final map = decoded.dartify();
  if (map is! Map) {
    throw FormatException('decodeRecord returned non-Map: ${map.runtimeType}');
  }
  return UspWsMessage.fromJs(Map<String, dynamic>.from(map));
}

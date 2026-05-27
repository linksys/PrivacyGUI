import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/ws_connection_state.dart';
import 'package:privacy_gui/core/usp/services/turbo_session_manager.dart';
import 'package:privacy_gui/core/usp/usp_ws_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_http_upload_strategy.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_upload_strategy.dart';

const _tag = '[FirmwareUpdate]';

/// WebSocket-based firmware upload strategy (Method 2).
///
/// Uses direct WebSocket connection to OBUSPA (`wss://router/usp-ws`),
/// bypassing the HTTP bridge. This provides:
/// - Binary transmission (no base64 overhead)
/// - Potentially larger chunk sizes (not limited by HTTP buffer)
/// - Lower latency per chunk
///
/// ## Lifecycle
/// 1. `prepare()`: turboStart → WS connect → WebSocketConnect handshake
/// 2. `uploadChunk()`: build Operate record → sendRecord
/// 3. `finalize()`: WS close → turboRelease
///
/// ## Prerequisites
/// - Router must expose WebSocket endpoint at `/usp-ws`
/// - Turbo channel must be available (not in use by another client)
/// - WASM client must have WebSocket API available
class FirmwareWsUploadStrategy implements FirmwareUploadStrategy {
  final TurboSessionManager _turboManager;
  final String _wsUrl;
  final String _fromId;
  final String _toId;

  UspWsClientWrapper? _wsClient;
  StreamSubscription? _messageSubscription;
  Completer<void>? _responseCompleter;

  FirmwareWsUploadStrategy({
    required TurboSessionManager turboManager,
    required String wsUrl,
    required String fromId,
    required String toId,
  })  : _turboManager = turboManager,
        _wsUrl = wsUrl,
        _fromId = fromId,
        _toId = toId;

  @override
  String get name => 'WebSocket';

  @override
  Future<bool> isAvailable() async {
    try {
      final status = await _turboManager.getStatus();
      return status.isIdle;
    } catch (e) {
      logger.w('$_tag isAvailable check failed: $e');
      return false;
    }
  }

  @override
  Future<void> prepare() async {
    logger.d('$_tag Preparing WebSocket upload...');

    // 1. Start turbo session (this pauses SSE)
    try {
      await _turboManager.start();
    } catch (e) {
      logger.e('$_tag Failed to start turbo session: $e');
      throw NetworkError(message: 'Failed to acquire turbo channel: $e');
    }

    // 2. Connect WebSocket
    try {
      _wsClient = await UspWsClientWrapper.connect(_wsUrl);
    } catch (e) {
      logger.e('$_tag Failed to connect WebSocket: $e');
      await _turboManager.release();
      throw NetworkError(message: 'WebSocket connection failed: $e');
    }

    // 3. Setup message listener
    _messageSubscription = _wsClient!.onMessage.listen((msg) {
      logger.d('$_tag Received: ${msg.msgType} (${msg.msgId})');
      if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
        if (msg.isError) {
          _responseCompleter!.completeError(
            UspCompleteFailureError(
              summary: msg.error?.message ?? 'Unknown error',
              failedPaths: const [],
            ),
          );
        } else {
          _responseCompleter!.complete();
        }
      }
    });

    // 4. Send WebSocketConnect handshake (TR-369 requirement)
    try {
      _responseCompleter = Completer<void>();
      await _wsClient!.sendWebSocketConnect(fromId: _fromId, toId: _toId);
      logger
          .d('$_tag WebSocketConnect handshake sent, waiting for response...');

      // Wait for handshake response
      await _responseCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          logger
              .w('$_tag WebSocketConnect response timeout (continuing anyway)');
        },
      );
      _responseCompleter = null;
      logger.d('$_tag WebSocketConnect handshake complete');
    } catch (e) {
      _responseCompleter = null;
      logger.e('$_tag WebSocketConnect handshake failed: $e');
      await finalize();
      throw NetworkError(message: 'WebSocket handshake failed: $e');
    }

    logger.i('$_tag WebSocket upload prepared');
  }

  @override
  Future<void> uploadChunk({
    required Uint8List chunk,
    required int sequenceNumber,
    required int totalChunks,
    required String md5,
    required int fileSize,
    required String commandKey,
  }) async {
    if (_wsClient == null || _wsClient!.state != WsConnectionState.open) {
      throw StateError('WebSocket not connected');
    }

    final args = <String, String>{
      'Content': base64Encode(chunk),
      'Filename': kRouterFirmwareFilename,
      'TotalFragment': totalChunks.toString(),
      'SequenceNumber': sequenceNumber.toString(),
      'CommandKey': commandKey,
      'Checksum': md5,
      'Filesize': fileSize.toString(),
    };

    _responseCompleter = Completer<void>();

    try {
      await _wsClient!.sendOperateRecord(
        command: 'Device.LocalAgent.X_LINKSYS_Download()',
        inputArgs: args,
        fromId: _fromId,
        toId: _toId,
      );

      // Wait for response with timeout
      await _responseCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Chunk $sequenceNumber upload timed out');
        },
      );
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw NetworkError(message: 'Chunk $sequenceNumber upload failed: $e');
    } finally {
      _responseCompleter = null;
    }
  }

  @override
  Future<void> finalize() async {
    logger.d('$_tag Finalizing WebSocket upload...');

    // Cancel message subscription
    await _messageSubscription?.cancel();
    _messageSubscription = null;

    // Close WebSocket
    try {
      _wsClient?.dispose();
    } catch (e) {
      logger.w('$_tag WebSocket close error (ignored): $e');
    }
    _wsClient = null;

    // Release turbo session (always, even if above steps failed)
    try {
      await _turboManager.release();
    } catch (e) {
      logger.w('$_tag Turbo release error (ignored): $e');
    }

    logger.i('$_tag WebSocket upload finalized');
  }
}

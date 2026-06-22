import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/turbo_session_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/ip_getter/ip_getter.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_chunker.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_http_upload_strategy.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service_factory.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_upload_strategy.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_ws_strategy_factory.dart';

typedef FirmwareUploadProgress = void Function(int sent, int total);

final firmwareLocalUploadServiceProvider = Provider<FirmwareLocalUploadService>(
  (ref) {
    final usp = ref.read(uspClientProvider)!;
    final lock = ref.read(uspMutationLockProvider);
    final turboManager = ref.read(turboSessionManagerProvider);

    // Get router host dynamically from window.location (web) or fallback
    final routerHost = getLocalIp(ref.read);

    return createFirmwareUploadService(
      client: usp,
      lock: lock,
      wsStrategyFactory: turboManager != null
          ? () async {
              // Fetch router's EndpointID dynamically (required for USP WebSocket)
              final endpointId = await _fetchEndpointId(usp);
              return createWsStrategy(
                turboManager: turboManager,
                wsUrl: 'wss://$routerHost/usp-ws',
                toId: endpointId,
              );
            }
          : null,
    );
  },
);

Future<String> _fetchEndpointId(UspClient client) async {
  final result = await client.get(['Device.LocalAgent.EndpointID']);
  final endpointId = result['Device.LocalAgent.EndpointID'] as String?;
  if (endpointId == null || endpointId.isEmpty) {
    throw StateError('Failed to fetch router EndpointID');
  }
  return endpointId;
}

class FirmwareUploadCancelledException implements Exception {
  const FirmwareUploadCancelledException();

  @override
  String toString() => 'Firmware upload cancelled by user';
}

const _tag = '[FirmwareUpdate]';

/// Pushes a local firmware image to the router.
///
/// Supports multiple upload strategies:
/// - **HTTP (Method 1)**: `Device.LocalAgent.X_LINKSYS_Download()` via
///   USP Operate → HTTP → bridge → UDS. Default, always available.
/// - **WebSocket (Method 2)**: Direct binary push to OBUSPA via
///   `wss://router/usp-ws`. Faster, but requires turbo channel lock.
///
/// Strategy selection is automatic: WebSocket is preferred when available,
/// with automatic fallback to HTTP on failure.
class FirmwareLocalUploadService {
  final UspClient _usp;
  final UspMutationLock _lock;
  final FirmwareChunker _chunker;

  /// Optional async WebSocket strategy factory. If null, HTTP is always used.
  /// Async to allow fetching router EndpointID before creating the strategy.
  final Future<FirmwareUploadStrategy> Function()? _wsStrategyFactory;

  /// The upload method used in the most recent upload.
  UploadMethod? _lastUsedMethod;

  FirmwareLocalUploadService(
    this._usp,
    this._lock, {
    FirmwareChunker? chunker,
    Future<FirmwareUploadStrategy> Function()? wsStrategyFactory,
  })  : _chunker = chunker ?? const FirmwareChunker(),
        _wsStrategyFactory = wsStrategyFactory;

  /// The upload method used in the most recent `uploadFile()` call.
  UploadMethod? get lastUsedMethod => _lastUsedMethod;

  /// Uploads [bytes] in chunks using the best available strategy.
  ///
  /// Automatically selects WebSocket when available, with fallback to HTTP.
  /// [isCancelled] is polled before each chunk; when it returns true the
  /// loop exits with [FirmwareUploadCancelledException].
  ///
  /// [commandKey] MUST be a numeric string (e.g. epoch milliseconds) — the
  /// router rejects non-numeric keys with INVALID_COMMAND_ARGS.
  Future<void> uploadFile({
    required Uint8List bytes,
    required String md5,
    required String commandKey,
    FirmwareUploadProgress? onProgress,
    bool Function()? isCancelled,
    Duration chunkTimeout = const Duration(seconds: 60),
  }) async {
    final total = _chunker.totalFragments(bytes.length);
    if (total == 0) {
      throw const InvalidInputError(
        detail: 'Cannot upload an empty firmware image',
      );
    }

    var strategy = await _selectStrategy(chunkTimeout: chunkTimeout);
    _lastUsedMethod = strategy is FirmwareHttpUploadStrategy
        ? UploadMethod.http
        : UploadMethod.websocket;
    logger.i('$_tag Using ${strategy.name} strategy for upload');

    try {
      await strategy.prepare();
    } catch (e) {
      // WebSocket prepare failed — fallback to HTTP
      if (strategy is! FirmwareHttpUploadStrategy) {
        logger.w(
            '$_tag ${strategy.name} prepare failed, falling back to HTTP: $e');
        await strategy.finalize();
        strategy = FirmwareHttpUploadStrategy(
          client: _usp,
          lock: _lock,
          chunkTimeout: chunkTimeout,
        );
        _lastUsedMethod = UploadMethod.http;
        logger.i('$_tag Fallback to ${strategy.name} strategy');
        await strategy.prepare();
      } else {
        rethrow;
      }
    }

    try {
      await _uploadWithStrategy(
        strategy: strategy,
        bytes: bytes,
        md5: md5,
        commandKey: commandKey,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
    } finally {
      await strategy.finalize();
    }
  }

  Future<FirmwareUploadStrategy> _selectStrategy({
    required Duration chunkTimeout,
  }) async {
    // Try WebSocket strategy if factory is provided
    if (_wsStrategyFactory != null) {
      logger.d(
          '$_tag WebSocket strategy factory available, creating strategy...');
      final wsStrategy = await _wsStrategyFactory();
      try {
        final available = await wsStrategy.isAvailable();
        logger.d('$_tag WebSocket isAvailable() returned: $available');
        if (available) {
          logger.d('$_tag WebSocket strategy available');
          return wsStrategy;
        } else {
          logger.d(
              '$_tag WebSocket strategy not available (turbo channel busy?)');
        }
      } catch (e, st) {
        logger.w('$_tag WebSocket availability check failed: $e\n$st');
      }
    } else {
      logger.d('$_tag No WebSocket strategy factory configured');
    }

    // Fallback to HTTP
    logger.d(
        '$_tag Using HTTP strategy (WebSocket unavailable or not configured)');
    return FirmwareHttpUploadStrategy(
      client: _usp,
      lock: _lock,
      chunkTimeout: chunkTimeout,
    );
  }

  Future<void> _uploadWithStrategy({
    required FirmwareUploadStrategy strategy,
    required Uint8List bytes,
    required String md5,
    required String commandKey,
    FirmwareUploadProgress? onProgress,
    bool Function()? isCancelled,
  }) async {
    // Use larger chunks for WebSocket strategy
    final chunker = strategy is FirmwareHttpUploadStrategy
        ? _chunker
        : const FirmwareChunker(chunkBytes: FirmwareChunker.wsChunkBytes);
    final total = chunker.totalFragments(bytes.length);
    onProgress?.call(0, total);

    for (final chunk in chunker.chunks(bytes)) {
      if (isCancelled?.call() ?? false) {
        throw const FirmwareUploadCancelledException();
      }

      await strategy.uploadChunk(
        chunk: chunk.data,
        sequenceNumber: chunk.sequenceNumber,
        totalChunks: total,
        md5: md5,
        fileSize: bytes.length,
        commandKey: commandKey,
      );

      onProgress?.call(chunk.sequenceNumber, total);
    }
  }

  int totalFragmentsFor(int byteLength) => _chunker.totalFragments(byteLength);

  UspClient get client => _usp;
}

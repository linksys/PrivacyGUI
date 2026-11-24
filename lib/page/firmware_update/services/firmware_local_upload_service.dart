import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firmware_operations.g.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_chunker.dart';

typedef FirmwareUploadProgress = void Function(int sent, int total);

/// Wire-format filename router-side `bbfdm.sysmngr` expects.
const kRouterFirmwareFilename = 'firmware.img';

final firmwareLocalUploadServiceProvider = Provider<FirmwareLocalUploadService>(
  (ref) => FirmwareLocalUploadService(
    ref.read(uspClientProvider)!,
    ref.read(uspMutationLockProvider),
  ),
);

const _tag = '[FirmwareUpdate]';

/// Pushes a local firmware image to the router.
///
/// One `Device.LocalAgent.X_LINKSYS_Download()` Operate per chunk, over the
/// same `UspClient` every other USP call uses, each under [UspMutationLock].
/// The chunk size is [FirmwareChunker.defaultChunkBytes].
///
/// This is the only upload path. A second one, a WebSocket push straight to
/// obuspa at `wss://router/usp-ws`, was removed in PrivacyGUI#1874 after the
/// firmware removed its endpoint: it gave unauthenticated Full Access to the
/// agent (Architecture#252).
class FirmwareLocalUploadService {
  final UspClient _usp;
  final UspMutationLock _lock;
  final FirmwareChunker _chunker;

  FirmwareLocalUploadService(
    this._usp,
    this._lock, {
    FirmwareChunker? chunker,
  }) : _chunker = chunker ?? const FirmwareChunker();

  /// Uploads [bytes] in chunks, one Operate at a time.
  ///
  /// [isCancelled] is polled before each chunk; when it returns true the
  /// loop exits with [OperationCancelledError].
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

    logger.i('$_tag Uploading ${bytes.length} bytes in $total chunks of '
        '${_chunker.chunkBytes} bytes');
    onProgress?.call(0, total);

    for (final chunk in _chunker.chunks(bytes)) {
      if (isCancelled?.call() ?? false) {
        throw const OperationCancelledError(
            detail: 'Firmware upload cancelled by user');
      }

      await _pushChunk(
        chunk: chunk.data,
        sequenceNumber: chunk.sequenceNumber,
        totalChunks: total,
        md5: md5,
        fileSize: bytes.length,
        commandKey: commandKey,
        timeout: chunkTimeout,
      );

      onProgress?.call(chunk.sequenceNumber, total);
    }
  }

  Future<void> _pushChunk({
    required Uint8List chunk,
    required int sequenceNumber,
    required int totalChunks,
    required String md5,
    required int fileSize,
    required String commandKey,
    required Duration timeout,
  }) {
    return _lock.withLock(
      () async {
        try {
          await FirmwareOperations.chunkedPush(
            _usp,
            content: base64Encode(chunk),
            filename: kRouterFirmwareFilename,
            totalFragment: totalChunks.toString(),
            sequenceNumber: sequenceNumber.toString(),
            commandKey: commandKey,
            checksum: md5,
            filesize: fileSize.toString(),
          );
        } on ServiceError {
          rethrow;
        } catch (e) {
          throw mapUspErrorToServiceError(e);
        }
      },
      timeout: timeout,
    );
  }

  int totalFragmentsFor(int byteLength) => _chunker.totalFragments(byteLength);
}

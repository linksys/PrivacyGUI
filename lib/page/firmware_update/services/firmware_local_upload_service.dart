import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/firmware_operations.g.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_chunker.dart';

typedef FirmwareUploadProgress = void Function(int sent, int total);

final firmwareLocalUploadServiceProvider = Provider<FirmwareLocalUploadService>(
  (ref) => FirmwareLocalUploadService(
    ref.read(uspClientProvider)!,
    ref.read(uspMutationLockProvider),
  ),
);

class FirmwareUploadCancelledException implements Exception {
  const FirmwareUploadCancelledException();

  @override
  String toString() => 'Firmware upload cancelled by user';
}

/// Wire-format filename router-side `bbfdm.sysmngr` expects. The router
/// reassembles all chunks into `/tmp/obuspa/firmware.img` regardless of the
/// user-picked filename, so we always send this constant — sending the
/// picker filename was confirmed to fail with USP_ERR_INVALID_COMMAND_ARGS
/// in `obuspa.log` (`download_file:470`). The user-visible picker name is
/// preserved separately in `FirmwareUpdateState.selectedFileName`.
const _kRouterFirmwareFilename = 'firmware.img';

/// Pushes a local firmware image to the router via Method 1
/// (`Device.LocalAgent.X_LINKSYS_Download()` over USP Operate → HTTP →
/// bridge → UDS). One operate call per chunk; sequence numbers are 1-based,
/// matching the wire format expected by OBUSPA.
class FirmwareLocalUploadService {
  final UspClient _usp;
  final UspMutationLock _lock;
  final FirmwareChunker _chunker;

  FirmwareLocalUploadService(
    this._usp,
    this._lock, {
    FirmwareChunker? chunker,
  }) : _chunker = chunker ?? const FirmwareChunker();

  /// Uploads [bytes] in raw 65535-byte chunks (default), base64-encoded per
  /// chunk. Holds [UspMutationLock] only for the duration of each individual
  /// chunkedPush so dashboard refreshes / SSE traffic can interleave between
  /// chunks. [isCancelled] is polled before each chunk; when it returns true
  /// the loop exits with [FirmwareUploadCancelledException] without sending
  /// further chunks. The chunked push has no resume support — a partial
  /// upload is abandoned by the router after a fresh sequence 1 arrives or
  /// after its accumulator times out.
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
        message: 'Cannot upload an empty firmware image',
      );
    }
    final filesize = bytes.length.toString();
    onProgress?.call(0, total);
    for (final chunk in _chunker.chunks(bytes)) {
      if (isCancelled?.call() ?? false) {
        throw const FirmwareUploadCancelledException();
      }
      await _lock.withLock(
        () async {
          try {
            await FirmwareOperations.chunkedPush(
              _usp,
              content: base64Encode(chunk.data),
              filename: _kRouterFirmwareFilename,
              totalFragment: total.toString(),
              sequenceNumber: chunk.sequenceNumber.toString(),
              commandKey: commandKey,
              checksum: md5,
              filesize: filesize,
            );
          } on ServiceError {
            rethrow;
          } catch (e) {
            throw mapUspErrorToServiceError(e);
          }
        },
        timeout: chunkTimeout,
      );
      onProgress?.call(chunk.sequenceNumber, total);
    }
  }

  int totalFragmentsFor(int byteLength) => _chunker.totalFragments(byteLength);

  UspClient get client => _usp;
}

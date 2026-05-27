import 'dart:convert';
import 'dart:typed_data';

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/firmware_operations.g.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_upload_strategy.dart';

/// Wire-format filename router-side `bbfdm.sysmngr` expects.
const kRouterFirmwareFilename = 'firmware.img';

/// HTTP-based firmware upload strategy (Method 1).
///
/// Uses `Device.LocalAgent.X_LINKSYS_Download()` via USP Operate → HTTP →
/// bridge → UDS. One HTTP operate call per chunk. This is the original
/// implementation, now wrapped in the strategy interface for interoperability
/// with the WebSocket strategy.
///
/// ## Characteristics
/// - Stateless (no connection setup/teardown)
/// - Uses [UspMutationLock] to coordinate with other USP operations
/// - Base64 encodes each chunk for wire transmission
/// - Works with existing HTTP transport, no special router support needed
class FirmwareHttpUploadStrategy implements FirmwareUploadStrategy {
  final UspClient _usp;
  final UspMutationLock _lock;
  final Duration _chunkTimeout;

  FirmwareHttpUploadStrategy({
    required UspClient client,
    required UspMutationLock lock,
    Duration chunkTimeout = const Duration(seconds: 60),
  })  : _usp = client,
        _lock = lock,
        _chunkTimeout = chunkTimeout;

  @override
  String get name => 'HTTP';

  @override
  Future<bool> isAvailable() async {
    // HTTP is always available when UspClient is initialized
    return _usp.isAuthenticated;
  }

  @override
  Future<void> prepare() async {
    // No-op for HTTP — stateless
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
    await _lock.withLock(
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
      timeout: _chunkTimeout,
    );
  }

  @override
  Future<void> finalize() async {
    // No-op for HTTP — stateless
  }
}

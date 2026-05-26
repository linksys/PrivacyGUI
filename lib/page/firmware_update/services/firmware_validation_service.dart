import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firmwareValidationServiceProvider =
    Provider<FirmwareValidationService>((_) => FirmwareValidationService());

enum FirmwareValidationFailureKind {
  empty,
  tooLarge,
  unsupportedExtension,
}

class FirmwareValidationFailure implements Exception {
  final FirmwareValidationFailureKind kind;
  final String message;
  const FirmwareValidationFailure(this.kind, this.message);

  @override
  String toString() => 'FirmwareValidationFailure: $message';
}

class FirmwareValidationResult {
  final String md5;
  final int size;
  final String filename;

  const FirmwareValidationResult({
    required this.md5,
    required this.size,
    required this.filename,
  });
}

/// Client-side guards for a firmware image before chunked push:
/// extension whitelist, sane size bounds, MD5 fingerprint computation.
///
/// MD5 here is for transport integrity (`X_LINKSYS_Download.Checksum`), not
/// security — the router applies its own signature check on flash.
class FirmwareValidationService {
  /// Reject anything below 1 MiB — almost certainly not a real image.
  static const int minBytes = 1 * 1024 * 1024;

  /// Reject anything above 256 MiB — current router family ships < 80 MB
  /// images; this guards against a wrong-file-typed accident exhausting RAM
  /// during base64 expansion.
  static const int maxBytes = 256 * 1024 * 1024;

  static const Set<String> allowedExtensions = {'img', 'bin'};

  /// Chunk size for the MD5 streaming hash. 1 MiB keeps each iteration short
  /// enough that the event-loop yield between chunks stays imperceptible while
  /// not paying excessive Future-scheduling overhead on a 70 MB image.
  static const int _md5ChunkBytes = 1 * 1024 * 1024;

  Future<FirmwareValidationResult> validate({
    required String filename,
    required Uint8List bytes,
  }) async {
    final size = bytes.length;
    if (size == 0) {
      throw const FirmwareValidationFailure(
        FirmwareValidationFailureKind.empty,
        'Firmware file is empty',
      );
    }
    if (size < minBytes) {
      throw FirmwareValidationFailure(
        FirmwareValidationFailureKind.tooLarge,
        'Firmware file is unexpectedly small ($size bytes)',
      );
    }
    if (size > maxBytes) {
      throw FirmwareValidationFailure(
        FirmwareValidationFailureKind.tooLarge,
        'Firmware file exceeds maximum size '
        '($size bytes > ${maxBytes ~/ (1024 * 1024)} MiB)',
      );
    }
    final ext = _extensionOf(filename);
    if (ext == null || !allowedExtensions.contains(ext)) {
      throw FirmwareValidationFailure(
        FirmwareValidationFailureKind.unsupportedExtension,
        'Unsupported file extension: ${ext ?? '(none)'}',
      );
    }
    final digest = await _md5Async(bytes);
    return FirmwareValidationResult(
      md5: digest,
      size: size,
      filename: filename,
    );
  }

  /// MD5 over [bytes] computed in chunks with a single-tick yield between
  /// each chunk. Keeps the main isolate responsive while a 70 MB image is
  /// fingerprinted — the synchronous `md5.convert(bytes)` stalls the UI for
  /// ~1-2 s on Web, which freezes the picker→validating transition.
  Future<String> _md5Async(Uint8List bytes) async {
    final sink = _DigestSink();
    final input = md5.startChunkedConversion(sink);
    for (var offset = 0; offset < bytes.length; offset += _md5ChunkBytes) {
      final end = (offset + _md5ChunkBytes < bytes.length)
          ? offset + _md5ChunkBytes
          : bytes.length;
      input.add(Uint8List.sublistView(bytes, offset, end));
      // Yield to the event loop so Flutter can paint the "validating" frame.
      await Future<void>.delayed(Duration.zero);
    }
    input.close();
    return sink.value.toString();
  }

  String? _extensionOf(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return null;
    return filename.substring(dot + 1).toLowerCase();
  }
}

/// Single-shot Digest sink for `Hash.startChunkedConversion`. Mirrors the
/// internal `DigestSink` shipped with `package:crypto` (which is library-private).
class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest value) {
    _value = value;
  }

  @override
  void close() {}
}

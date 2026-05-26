import 'dart:math' as math;
import 'dart:typed_data';

import 'package:privacy_gui/page/firmware_update/models/firmware_chunk.dart';

class FirmwareChunker {
  /// Raw bytes per chunk (pre-base64). 65535 is the empirically observed
  /// transport upper bound — see `doc/usp/integration/firmware_chunk_size_validation.md`.
  static const int defaultChunkBytes = 65535;

  final int chunkBytes;

  const FirmwareChunker({this.chunkBytes = defaultChunkBytes});

  int totalFragments(int byteLength) =>
      byteLength == 0 ? 0 : (byteLength / chunkBytes).ceil();

  Iterable<FirmwareChunk> chunks(Uint8List bytes) sync* {
    final total = totalFragments(bytes.length);
    for (var i = 0; i < total; i++) {
      final start = i * chunkBytes;
      final end = math.min(start + chunkBytes, bytes.length);
      yield FirmwareChunk(
        sequenceNumber: i + 1,
        totalFragment: total,
        data: Uint8List.sublistView(bytes, start, end),
      );
    }
  }
}

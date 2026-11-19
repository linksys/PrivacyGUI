import 'dart:math' as math;
import 'dart:typed_data';

import 'package:privacy_gui/page/firmware_update/models/firmware_chunk.dart';

class FirmwareChunker {
  /// Raw bytes per chunk, before base64: 192 KiB, so each
  /// `X_LINKSYS_Download()` Operate carries 256 KiB of base64 `Content`.
  ///
  /// This was 65,535 until PrivacyGUI#1874. Per the firmware team that number
  /// was not a transport limit: HTTP was held there because `usp-bridge`
  /// dropped data on a partial write to the obuspa socket, fixed in
  /// feed_uspapi#44. They measured a ~58 MB image on an M60 at 16 s with
  /// 64 KiB chunks and 11 s with 192 KiB ones, against 10 s for the retired
  /// WebSocket path, which used this same size.
  ///
  /// On firmware without feed_uspapi#44, chunks this size can fail with partial
  /// writes. The local GUI ships inside the firmware image, so a build with
  /// this value runs on firmware that has the fix.
  static const int defaultChunkBytes = 196608;

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

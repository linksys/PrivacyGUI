import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_chunker.dart';

void main() {
  group('FirmwareChunker', () {
    test('totalFragments rounds up partial chunks', () {
      const chunker = FirmwareChunker(chunkBytes: 100);
      expect(chunker.totalFragments(0), 0);
      expect(chunker.totalFragments(1), 1);
      expect(chunker.totalFragments(100), 1);
      expect(chunker.totalFragments(101), 2);
      expect(chunker.totalFragments(250), 3);
    });

    test('chunks yields sequential fragments covering the full payload', () {
      const chunker = FirmwareChunker(chunkBytes: 4);
      final bytes = Uint8List.fromList(List<int>.generate(10, (i) => i));

      final chunks = chunker.chunks(bytes).toList();

      expect(chunks, hasLength(3));
      expect(chunks[0].sequenceNumber, 1);
      expect(chunks[0].totalFragment, 3);
      expect(chunks[0].data, equals(Uint8List.fromList([0, 1, 2, 3])));
      expect(chunks[1].data, equals(Uint8List.fromList([4, 5, 6, 7])));
      expect(chunks[2].data, equals(Uint8List.fromList([8, 9])));
    });

    test('chunks on empty payload yields nothing', () {
      const chunker = FirmwareChunker(chunkBytes: 4);
      expect(chunker.chunks(Uint8List(0)), isEmpty);
    });

    // 192 KiB is what firmware accepts over HTTP since feed_uspapi#44
    // (PrivacyGUI#1874). It was 65,535 before that fix.
    test('default chunk size is 192 KiB', () {
      expect(FirmwareChunker.defaultChunkBytes, 196608);
      expect(const FirmwareChunker().chunkBytes, 196608);
    });
  });
}

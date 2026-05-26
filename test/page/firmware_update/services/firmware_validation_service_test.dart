import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_validation_service.dart';

void main() {
  late FirmwareValidationService service;

  setUp(() {
    service = FirmwareValidationService();
  });

  Uint8List bytesOf(int size, {int seed = 0}) {
    final out = Uint8List(size);
    for (var i = 0; i < size; i++) {
      out[i] = (i + seed) & 0xff;
    }
    return out;
  }

  group('FirmwareValidationService', () {
    test('accepts a normal-sized .img file and returns md5/size/filename',
        () async {
      final bytes = bytesOf(2 * 1024 * 1024);
      final result =
          await service.validate(filename: 'router.img', bytes: bytes);

      expect(result.size, bytes.length);
      expect(result.filename, 'router.img');
      expect(result.md5, md5.convert(bytes).toString());
      expect(result.md5.length, 32);
    });

    test('accepts .bin extension', () async {
      final bytes = bytesOf(2 * 1024 * 1024);
      final result =
          await service.validate(filename: 'router.bin', bytes: bytes);
      expect(result.filename, 'router.bin');
    });

    test('rejects empty file with empty kind', () {
      expect(
        () => service.validate(filename: 'fw.img', bytes: Uint8List(0)),
        throwsA(
          isA<FirmwareValidationFailure>().having(
            (e) => e.kind,
            'kind',
            FirmwareValidationFailureKind.empty,
          ),
        ),
      );
    });

    test('rejects below-min file with tooLarge kind', () {
      // The validator reports both small and large outside-bounds as tooLarge.
      expect(
        () => service.validate(filename: 'fw.img', bytes: bytesOf(1024)),
        throwsA(
          isA<FirmwareValidationFailure>().having(
            (e) => e.kind,
            'kind',
            FirmwareValidationFailureKind.tooLarge,
          ),
        ),
      );
    });

    test('rejects above-max file with tooLarge kind', () {
      // 257 MiB exceeds the 256 MiB cap. Build a sparse buffer to keep the
      // test cheap.
      const size = FirmwareValidationService.maxBytes + 1;
      final bytes = Uint8List(size);
      expect(
        () => service.validate(filename: 'fw.img', bytes: bytes),
        throwsA(
          isA<FirmwareValidationFailure>().having(
            (e) => e.kind,
            'kind',
            FirmwareValidationFailureKind.tooLarge,
          ),
        ),
      );
    });

    test('rejects unsupported extension', () {
      expect(
        () => service.validate(
            filename: 'fw.zip', bytes: bytesOf(2 * 1024 * 1024)),
        throwsA(
          isA<FirmwareValidationFailure>().having(
            (e) => e.kind,
            'kind',
            FirmwareValidationFailureKind.unsupportedExtension,
          ),
        ),
      );
    });

    test('rejects extensionless filename', () {
      expect(
        () => service.validate(
            filename: 'firmware', bytes: bytesOf(2 * 1024 * 1024)),
        throwsA(
          isA<FirmwareValidationFailure>().having(
            (e) => e.kind,
            'kind',
            FirmwareValidationFailureKind.unsupportedExtension,
          ),
        ),
      );
    });

    test('extension check is case-insensitive', () async {
      final result = await service.validate(
        filename: 'router.IMG',
        bytes: bytesOf(2 * 1024 * 1024),
      );
      expect(result.filename, 'router.IMG');
    });

    test('rejects trailing-dot filename', () {
      expect(
        () => service.validate(
            filename: 'router.', bytes: bytesOf(2 * 1024 * 1024)),
        throwsA(isA<FirmwareValidationFailure>().having(
          (e) => e.kind,
          'kind',
          FirmwareValidationFailureKind.unsupportedExtension,
        )),
      );
    });

    test('toString contains the failure message', () async {
      try {
        await service.validate(
            filename: 'fw.zip', bytes: bytesOf(2 * 1024 * 1024));
        fail('expected failure');
      } on FirmwareValidationFailure catch (e) {
        expect(e.toString(), contains('Unsupported file extension'));
      }
    });
  });
}

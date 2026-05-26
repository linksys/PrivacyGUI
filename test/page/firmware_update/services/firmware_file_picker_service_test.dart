import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';

void main() {
  group('FirmwareFilePickerService', () {
    test('returns null when user cancels the dialog', () async {
      final service = FirmwareFilePickerService()
        ..pickFilesOverride = ({
          String? dialogTitle,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          bool withData = false,
        }) async =>
            null;

      final result = await service.pickFirmwareImage();
      expect(result, isNull);
    });

    test('returns null when picker returns empty file list', () async {
      final service = FirmwareFilePickerService()
        ..pickFilesOverride = ({
          String? dialogTitle,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          bool withData = false,
        }) async =>
            FilePickerResult(const []);

      final result = await service.pickFirmwareImage();
      expect(result, isNull);
    });

    test('returns FirmwarePickedFile populated from PlatformFile', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final service = FirmwareFilePickerService()
        ..pickFilesOverride = ({
          String? dialogTitle,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          bool withData = false,
        }) async =>
            FilePickerResult([
              PlatformFile(
                name: 'fw.img',
                size: bytes.length,
                bytes: bytes,
              ),
            ]);

      final result = await service.pickFirmwareImage();

      expect(result, isNotNull);
      expect(result!.name, 'fw.img');
      expect(result.size, bytes.length);
      expect(result.bytes, bytes);
    });

    test('throws FirmwarePickerError when bytes are unavailable', () async {
      final service = FirmwareFilePickerService()
        ..pickFilesOverride = ({
          String? dialogTitle,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          bool withData = false,
        }) async =>
            FilePickerResult([
              PlatformFile(name: 'fw.img', size: 1024, bytes: null),
            ]);

      expect(
        () => service.pickFirmwareImage(),
        throwsA(isA<FirmwarePickerError>()),
      );
    });

    test('forwards expected dialog options to the pickFiles call', () async {
      String? capturedTitle;
      FileType? capturedType;
      List<String>? capturedExtensions;
      bool? capturedWithData;

      final service = FirmwareFilePickerService()
        ..pickFilesOverride = ({
          String? dialogTitle,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          bool withData = false,
        }) async {
          capturedTitle = dialogTitle;
          capturedType = type;
          capturedExtensions = allowedExtensions;
          capturedWithData = withData;
          return null;
        };

      await service.pickFirmwareImage();

      expect(capturedTitle, 'Select firmware image');
      expect(capturedType, FileType.custom);
      expect(capturedExtensions, ['img', 'bin']);
      expect(capturedWithData, isTrue);
    });
  });
}

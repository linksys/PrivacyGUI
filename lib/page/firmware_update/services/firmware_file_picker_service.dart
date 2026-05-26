import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firmwareFilePickerServiceProvider =
    Provider<FirmwareFilePickerService>((_) => FirmwareFilePickerService());

class FirmwarePickedFile {
  final String name;
  final int size;
  final Uint8List bytes;

  const FirmwarePickedFile({
    required this.name,
    required this.size,
    required this.bytes,
  });
}

/// Thin wrapper over `package:file_picker` so the rest of the codebase can
/// depend on a Dart-pure surface (mockable in tests, web/desktop neutral).
class FirmwareFilePickerService {
  /// Optional override for tests — when provided, [pickFirmwareImage] returns
  /// its result instead of opening the OS file picker.
  Future<FilePickerResult?> Function({
    String? dialogTitle,
    FileType type,
    List<String>? allowedExtensions,
    bool withData,
  })? pickFilesOverride;

  Future<FirmwarePickedFile?> pickFirmwareImage() async {
    final pickFn = pickFilesOverride ?? FilePicker.platform.pickFiles;
    final result = await pickFn(
      dialogTitle: 'Select firmware image',
      type: FileType.custom,
      allowedExtensions: const ['img', 'bin'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      throw const FirmwarePickerError('File bytes unavailable');
    }
    return FirmwarePickedFile(
      name: file.name,
      size: file.size,
      bytes: bytes,
    );
  }
}

class FirmwarePickerError implements Exception {
  final String message;
  const FirmwarePickerError(this.message);

  @override
  String toString() => 'FirmwarePickerError: $message';
}

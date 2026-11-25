// The fallback of the conditional import in utils.dart and the Wi-Fi QR
// pages, for a platform with neither dart:io nor dart:html. Every real build
// picks export_mobile.dart or export_web.dart instead.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/util/export_selector/export_base.dart';

void main() {
  test('a platform without io or html cannot export', () {
    expect(exportFile(content: 'x', fileName: 'log'), throwsUnimplementedError);
    expect(
        exportFileFromBytes(utf8Bytes: Uint8List(0), fileName: 'qr'),
        throwsUnimplementedError);
  });
}

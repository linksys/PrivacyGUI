// Off the web, exporting the log hands it to the system share sheet as a
// text file (Utils.exportLogFile). The share sheet is share_plus's channel.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:privacy_gui/util/export_selector/export_mobile.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory temp;

  /// What the share sheet was handed, with each file's content read while
  /// the sheet had it.
  late List<({Map<Object?, Object?> args, List<String> contents})> shared;

  /// What the share sheet answers: a non-empty result is a share, an empty
  /// one a dismissal.
  late String sheetAnswer;

  setUpAll(() => logger.d('export_mobile_test'));

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('export_');
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => temp.path);
    await Storage.init();
    shared = [];
    sheetAnswer = 'com.apple.UIKit.activity.Mail';
    messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'), (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      shared.add((
        args: args,
        contents: [
          for (final path in args['paths'] as List)
            File(path as String).readAsStringSync(),
        ],
      ));
      return sheetAnswer;
    });
  });

  tearDown(() => temp.deleteSync(recursive: true));

  group('exportFile', () {
    test('shares the content as a text file, and removes it once shared',
        () async {
      final result = await exportFile(
        content: 'line 1\nline 2\n',
        fileName: 'log-2026-11-25_10_00_00',
        text: 'Linksys Log',
        subject: 'Log file',
      );

      final sheet = shared.single;
      expect(sheet.args['paths'],
          ['${temp.path}/log-2026-11-25_10_00_00.txt']);
      expect(sheet.args['mimeTypes'], ['text/plain']);
      expect(sheet.args['text'], 'Linksys Log');
      expect(sheet.args['subject'], 'Log file');
      expect(sheet.contents, ['line 1\nline 2\n']);
      expect(result?.status, ShareResultStatus.success);
      expect(File('${temp.path}/log-2026-11-25_10_00_00.txt').existsSync(),
          isFalse);
    });

    test('keeps the file when the share sheet is dismissed', () async {
      sheetAnswer = '';

      final result =
          await exportFile(content: 'line 1\n', fileName: 'log-dismissed');

      expect(result?.status, ShareResultStatus.dismissed);
      expect(File('${temp.path}/log-dismissed.txt').readAsStringSync(),
          'line 1\n');
    });
  });

  // The Wi-Fi QR code's download is web-only: off the web it does nothing.
  test('exportFileFromBytes shares nothing off the web', () async {
    final result = await exportFileFromBytes(
        utf8Bytes: Uint8List.fromList([1, 2, 3]), fileName: 'wifi-qr.png');

    expect(result, isNull);
    expect(shared, isEmpty);
  });
}

// Storage: the app's temp directory and the files it keeps there (the log
// file, shared logs, downloads). Off the web, init() asks path_provider for
// the directories; here path_provider answers with a directory of the test's
// own.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late Directory docs;

  setUpAll(() {
    // The app's logger keeps the log file Storage names when it is first
    // used. Using it now, before init(), keeps it out of the test's files.
    logger.d('storage_test');
  });

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('storage_temp_');
    docs = Directory.systemTemp.createTempSync('storage_docs_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => switch (call.method) {
                  'getTemporaryDirectory' => temp.path,
                  'getApplicationDocumentsDirectory' => docs.path,
                  _ => null,
                });
    await Storage.init();
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
    docs.deleteSync(recursive: true);
  });

  test('init takes the temp and documents directories path_provider gives',
      () {
    expect(Storage.tempDirectory?.path, temp.path);
    expect(Storage.docDirectory?.path, docs.path);
  });

  test('init creates an empty log file in the temp directory', () {
    expect(Storage.logFileUri.toFilePath(), '${temp.path}/logger.txt');
    expect(File('${temp.path}/logger.txt').readAsStringSync(), '');
  });

  test('init keeps a log file that is already there', () async {
    File('${temp.path}/logger.txt').writeAsStringSync('earlier lines\n');

    await Storage.init();

    expect(File('${temp.path}/logger.txt').readAsStringSync(),
        'earlier lines\n');
  });

  test('createLoggerFile makes a fresh log file after one was shared away',
      () {
    Storage.deleteFile(Storage.logFileUri);
    expect(File('${temp.path}/logger.txt').existsSync(), isFalse);

    Storage.createLoggerFile();

    expect(File('${temp.path}/logger.txt').readAsStringSync(), '');
  });

  test('saveFile creates a file, and replaces what an earlier save wrote',
      () async {
    final uri = Uri.parse('${temp.path}/log-2026-11-25.txt');

    await Storage.saveFile(uri, 'first');
    expect(File.fromUri(uri).readAsStringSync(), 'first');

    await Storage.saveFile(uri, 'second');
    expect(File.fromUri(uri).readAsStringSync(), 'second');
  });

  test('saveByteFile writes the bytes as they are', () async {
    final uri = Uri.parse('${temp.path}/speed.bin');

    await Storage.saveByteFile(uri, Uint8List.fromList([0, 128, 255]));

    expect(File.fromUri(uri).readAsBytesSync(), [0, 128, 255]);
  });

  test('deleteFile removes the file', () async {
    final uri = Uri.parse('${temp.path}/x.txt');
    await Storage.saveFile(uri, 'x');

    Storage.deleteFile(uri);

    expect(File.fromUri(uri).existsSync(), isFalse);
  });
}

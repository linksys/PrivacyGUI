// What the app's log records, off the web: CustomOutput appends each line to
// the log file the user can export, with secrets masked, and the exported log
// starts with the package and screen info.
//
// On the web, CustomOutput keeps the lines in memory instead (_recordLog), and
// only there; kIsWeb is false on the Dart VM, so that path is not tested here.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:privacy_gui/core/utils/fernet_manager.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';

OutputEvent _event(Level level, String line) =>
    OutputEvent(LogEvent(level, line), [line]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late File logFile;

  setUpAll(() {
    // The app's logger keeps the log file Storage names when it is first
    // used. Using it now, before init(), keeps its own lines out of the
    // test's log file.
    logger.d('logger_test');
  });

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('logger_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => temp.path);
    await Storage.init();
    logFile = File('${temp.path}/logger.txt');
    // No router key yet, as before the first login.
    FernetManager().resetForTest();
  });

  tearDown(() => temp.deleteSync(recursive: true));

  /// The log file's content once [lines] lines are in it. CustomOutput
  /// writes without being awaited.
  Future<String> logFileWith(int lines) async {
    for (var i = 0; i < 200; i++) {
      final content = logFile.readAsStringSync();
      if ('\n'.allMatches(content).length >= lines) return content;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return logFile.readAsStringSync();
  }

  group('CustomOutput, off the web', () {
    test('appends each line to the log file', () async {
      final output = CustomOutput();

      output.output(_event(Level.info, '[Route]: whereToGo - login'));
      await logFileWith(1);
      output.output(_event(Level.error, '[Auth]: logout'));

      expect(await logFileWith(2),
          '[Route]: whereToGo - login\n[Auth]: logout\n');
    });

    test('writes passwords and other secrets masked', () async {
      CustomOutput().output(_event(Level.debug,
          'BODY: {"adminPassword":"Hunter2","passphrase":"wifi-secret"}'));

      expect(await logFileWith(1),
          'BODY: {"adminPassword":"************","passphrase":"************"}\n');
    });

    test('writes a JNAP authorization header without the credentials',
        () async {
      CustomOutput().output(_event(Level.info,
          'HEADERS: {X-JNAP-Authorization: Basic YWRtaW46YWRtaW4=}'));

      expect(await logFileWith(1),
          'HEADERS: {X-JNAP-Authorization: Basic ************}\n');
    });

    test('writes web addresses with their colons and dots replaced', () async {
      CustomOutput()
          .output(_event(Level.info, 'URL: https://192.168.1.1/JNAP/'));

      expect(await logFileWith(1), 'URL: https-//192-168-1-1/JNAP/\n');
    });

    test('keeps trace lines out of the file', () async {
      final output = CustomOutput();

      output.output(_event(Level.trace, 'polling tick'));
      output.output(_event(Level.debug, 'polling done'));

      expect(await logFileWith(1), 'polling done\n');
    });

    test('writes nothing once the log file is gone', () {
      logFile.deleteSync();

      CustomOutput().output(_event(Level.error, 'lost'));

      expect(logFile.existsSync(), isFalse);
    });
  });

  group('the exported log', () {
    setUp(() => PackageInfo.setMockInitialValues(
          appName: 'Linksys',
          packageName: 'com.linksys.privacygui',
          version: '1.3.7',
          buildNumber: '581',
          buildSignature: '',
        ));

    test('starts with the package, its source and the platform', () async {
      final lines = (await getPackageInfo()).split('\n');

      expect(lines.sublist(0, 7), [
        '================================= Package Info '
            '=================================',
        'App Name: Linksys',
        'App ID: com.linksys.privacygui',
        'App Build Number: 581',
        'App Version: 1.3.7',
        // A test build has no revision, and is neither forced local nor
        // remote.
        'Source Revision: unknown',
        'Force: none',
      ]);
      expect(lines[7], startsWith('Platform OS: '));
      expect(lines[8], startsWith('OS version: '));
      // flutter test reports Android as the target platform.
      expect(lines[9], 'OS: android');
      expect(
          lines[10],
          '================================= Device Info '
          '==================================');
    });

    // On the web this is the exported log (get_log_web.dart). The sections
    // stay empty on the Dart VM, which never fills the web log.
    testWidgets('on the web, lists its sections in order', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }));

      final log = await outputFullWebLog(context);

      final headers = [
        'Package Info',
        'Screen Info',
        'View History',
        'Custom Tag Summary',
        'State Management',
        'Full Logs',
      ].map((title) => log.indexOf(' $title ')).toList();
      expect(headers, everyElement(greaterThanOrEqualTo(0)));
      expect(headers, orderedEquals([...headers]..sort()));
    });
  });
}

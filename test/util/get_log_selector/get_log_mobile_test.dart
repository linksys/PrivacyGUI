// Off the web, the exported log is the package and screen info followed by
// the log file CustomOutput writes (Utils.exportLogFile).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:privacy_gui/util/get_log_selector/get_log_mobile.dart';

void main() {
  late Directory temp;

  setUpAll(() => logger.d('get_log_mobile_test'));

  setUp(() {
    temp = Directory.systemTemp.createTempSync('get_log_');
    PackageInfo.setMockInitialValues(
      appName: 'Linksys',
      packageName: 'com.linksys.privacygui',
      version: '1.3.7',
      buildNumber: '581',
      buildSignature: '',
    );
  });

  tearDown(() => temp.deleteSync(recursive: true));

  testWidgets('is the package info, the screen info, then the log file',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => temp.path);
    await tester.runAsync(() async => await Storage.init());
    File('${temp.path}/logger.txt')
        .writeAsStringSync('[Route]: whereToGo - login\n[Auth]: logout\n');
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));

    final log = (await tester.runAsync(() => getLog(context)))!;

    expect(log, startsWith('================================= Package Info'));
    expect(log, contains('App Version: 1.3.7\n'));
    expect(
        log.indexOf('================================= Screen Info'),
        greaterThan(log.indexOf('App Version: 1.3.7')));
    expect(log, endsWith('\n[Route]: whereToGo - login\n[Auth]: logout\n'));
  });
}

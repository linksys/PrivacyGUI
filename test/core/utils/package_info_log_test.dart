import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Coverage for the one line of the exported log that says which source a build
/// came from (#1573).
///
/// [getPackageInfo] is the only log header in the app: the web export
/// (`outputFullWebLog`) and the mobile export (`get_log_mobile.dart`) both call it,
/// so this file is what stops the revision going missing from either.
///
/// The assertion reads the produced header rather than the constant it interpolates.
/// Asserting `BuildConfig.sourceRevision == 'unknown'` would pass with the line
/// deleted, which is the whole failure this test exists to catch.
///
/// No `device_info` stub is needed, and that is a property of the host rather than
/// luck: `_getDeviceInfo` switches on `Platform.isIOS` / `Platform.isAndroid`, which
/// are the *host* OS, so under `flutter test` on macOS or on CI's Linux it takes the
/// `else` branch and returns an empty string. `defaultTargetPlatform` is android in
/// this harness, but nothing in that function reads it. A `package_info` stub is
/// still required — that plugin has no platform implementation here at all.
void main() {
  // No `testWidgets` in this file, so nothing else initialises the binding that
  // owns the mock messenger.
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'PrivacyGUI',
          'packageName': 'com.linksys.privacygui',
          'version': '2.7.1',
          'buildNumber': '700534',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('the log header carries the source revision', () async {
    final header = await getPackageInfo();

    expect(header, contains('Source Revision: ${BuildConfig.sourceRevision}'));
  });

  test('the source revision is a line of its own, next to the app version',
      () async {
    final lines = (await getPackageInfo()).split('\n');

    final versionIndex =
        lines.indexWhere((line) => line.startsWith('App Version:'));
    final revisionIndex =
        lines.indexWhere((line) => line.startsWith('Source Revision:'));

    expect(versionIndex, isNonNegative);
    // Its own line, so a reader scanning the header finds it without parsing, and
    // adjacent to the version because the two answer the same question together.
    expect(revisionIndex, versionIndex + 1);
  });

  test('a build made outside build_web.sh reports an unknown revision',
      () async {
    // What `flutter test` itself is: no `--dart-define=source_revision`, so the
    // default is what the header must carry. AC 2 — the absence of the stamp is
    // reported, never guessed at and never fatal.
    expect(BuildConfig.sourceRevision, 'unknown');
    expect(await getPackageInfo(), contains('Source Revision: unknown'));
  });
}

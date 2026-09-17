import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/page/landing/views/home_view.dart';

import '../../../layout_gate/families/page_surface_family.dart';

/// Coverage for the source revision on the landing footer's version line (#1573).
///
/// The second of the two render sites, and the one that had no assertion on what
/// it says: `page.home` sweeps this page over 234 cells, but an overflow sweep
/// asserts that the line laid out, never that the revision is in it. Deleting the
/// interpolation left the whole gate green.
///
/// Hosted with [pageSurfaceHost] rather than a `MaterialApp` of its own, because
/// `HomeView` renders `UiKitPageView`, whose `UspTopBar` calls `GoRouter.of` in
/// `didChangeDependencies` without a guard. That helper is the layout gate's, and
/// reusing it is the point: a copy here would be a second router-and-overrides
/// setup to keep in step with the app's.
///
/// One thing this file cannot reach: the `- local` half of the line is behind
/// `kIsWeb`, and `flutter test` on the VM harness reports web as false. Asserting
/// it needs `--platform chrome`, which nothing in this repo's CI runs, so what is
/// pinned below is the off-web shape of the string.
void main() {
  const packageInfoChannel =
      MethodChannel('dev.fluttercommunity.plus/package_info');

  // Four dot-separated parts, which is what the build job writes into
  // `assets/resources/versions.json` — the same fixture the popup's test uses, for
  // the same reason.
  const shippedVersion = '2.7.1.700534';

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (call) async {
      if (call.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'PrivacyGUI',
          'packageName': 'com.linksys.privacygui',
          'version': shippedVersion,
          'buildNumber': '700534',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(pageSurfaceHost(
      view: const HomeView(),
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the footer version line names the source revision',
      (tester) async {
    await pumpHome(tester);

    // The whole string, not a substring: `textContaining('unknown')` would pass
    // with the revision rendered as a line of its own, and an assertion on
    // `BuildConfig.sourceRevision` alone would pass with the interpolation gone.
    expect(
      find.text('version $shippedVersion (${BuildConfig.sourceRevision})'),
      findsOneWidget,
    );
  });

  testWidgets('the footer renders one version line, not two', (tester) async {
    await pumpHome(tester);

    // The revision was appended to the existing line rather than added beside it.
    // A second `Text` mentioning the version would mean the footer grew a row,
    // which is what the sweep's 234 cells measure the height of but cannot name.
    final versionTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => (text.data ?? '').contains('version '))
        .toList();

    expect(versionTexts, hasLength(1));
    expect(
        versionTexts.single.data, contains('(${BuildConfig.sourceRevision})'));
  });
}

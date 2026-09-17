import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../../util/app_test_fonts.dart';

/// Coverage for the source revision on the settings popup's version line (#1573).
///
/// Deliberately its own file rather than a case added to
/// `general_settings_widget_test.dart`, which carries `@Tags(['ui'])`. Both CI jobs
/// pass `--exclude-tags="golden||loc||ui"`, so a case added there would run only for
/// whoever remembered `flutter test --tags ui` locally — and this is a line that
/// goes missing silently, which is the one thing a test that never runs cannot
/// catch. 20 of the repo's 25 `*_widget_test.dart` files are untagged for the same
/// reason.
///
/// The other render site, the landing page's footer, has no test of its own:
/// `UiKitPageView` pulls in `usp_top_bar`, so hosting `HomeView` standalone means
/// supplying the whole provider set, which is why the layout gate hosts `page.home`
/// itself. That gate asserts the line renders and does not overflow, not what it
/// says.
void main() {
  const packageInfoChannel =
      MethodChannel('dev.fluttercommunity.plus/package_info');

  setUpAll(() async {
    // Real fonts, because one of the assertions below is a width. Without this the
    // harness falls back to a fixed-width face and every pixel it reports is
    // fiction — see that test for the number it produced.
    await loadAppFonts();

    final getIt = GetIt.instance;
    final config = ThemeJsonConfig.defaultConfig();
    if (!getIt.isRegistered<ThemeJsonConfig>()) {
      getIt.registerSingleton<ThemeJsonConfig>(config);
    }
    // The widget reads the dark theme out of getIt for its icon colour, so the
    // host has to provide one.
    if (!getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
      getIt.registerSingleton<ThemeData>(
        config.createDarkTheme(),
        instanceName: 'darkThemeData',
      );
    }
  });

  // What a shipped build renders: the build job writes this whole string into
  // `assets/resources/versions.json`, four dot-separated parts and not three.
  // Deliberately not '2.7.1' — the line's width is the thing at risk, and a
  // three-part version understates it by six characters.
  const shippedVersion = '2.7.1.700534';
  const versionLine = 'version $shippedVersion (${BuildConfig.sourceRevision})';

  setUp(() {
    // Stubbed so the version half of the line is a known string too. `getVersion()`
    // prefers `assets/resources/versions.json`, which the build job writes and no
    // test tree has, so it falls through to this.
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

  Widget buildHost() => ProviderScope(
        child: MaterialApp(
          theme: GetIt.instance.get<ThemeData>(instanceName: 'darkThemeData'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: GeneralSettingsWidget()),
        ),
      );

  Future<void> openPopup(WidgetTester tester) async {
    // Targeted by identifier rather than `find.byType(Icon).first`, which is what
    // the neighbouring test file does: `.first` is a positional selector, so any
    // Icon inserted above this one in the tree would silently redirect the tap and
    // the assertions would then be about whatever that opened.
    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is Semantics &&
        widget.properties.identifier == 'now-topbar-icon-general-settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('the version line names the source revision', (tester) async {
    await tester.pumpWidget(buildHost());
    await openPopup(tester);

    // The whole rendered line, not a substring of it: an assertion on
    // `BuildConfig.sourceRevision` alone would pass with the interpolation deleted,
    // and one on `textContaining('unknown')` would pass if the revision landed
    // somewhere else in the popup.
    expect(find.text(versionLine), findsOneWidget);
  });

  testWidgets('the version line fits the popup without wrapping',
      (tester) async {
    // The one render site the layout gate cannot reach. `page_chrome` builds
    // `GeneralSettingsWidget` — which is why that family stubs `package_info` — but
    // never taps it open, so none of its 1,248 cells contain this line. The width
    // does not vary with the screen either: the panel is pinned to 240-280px, so
    // this single width is the whole surface.
    //
    // Worth having because wrapping here is silent. A `Center` over a `Column`
    // child just grows a second line: nothing throws, nothing clips, and no
    // overflow gate anywhere would notice.
    await tester.pumpWidget(buildHost());
    await openPopup(tester);

    final line = tester.renderObject<RenderBox>(find.text(versionLine));

    // Max intrinsic width is what the string needs on one line, so comparing it
    // with the box it was given asks the wrap's question before the wrap happens.
    //
    // Measured 172.8px inside 230.0px — 57px of slack, against which the single
    // character between `unknown` (7) and a real short hash (8) is about 6px. The
    // first version of this test ran without `loadAppFonts()` and measured 360px in
    // the same 230px box: 30 characters at exactly 12px, i.e. the harness's
    // fixed-width fallback rather than the shipped face. If this test ever fails,
    // check that the fonts still load before believing the pixels.
    expect(
      line.getMaxIntrinsicWidth(double.infinity),
      lessThan(line.constraints.maxWidth),
    );
  });

  testWidgets('the revision sits inside the version line, not beside it',
      (tester) async {
    await tester.pumpWidget(buildHost());
    await openPopup(tester);

    // `now-general-text-version` is the hook the E2E specs read, so the revision
    // has to be inside that node to travel with it.
    final versionNode = find.byWidgetPredicate((widget) =>
        widget is Semantics &&
        widget.properties.identifier == 'now-general-text-version');

    expect(versionNode, findsOneWidget);
    expect(
      find.descendant(
        of: versionNode,
        matching: find.textContaining('(${BuildConfig.sourceRevision})'),
      ),
      findsOneWidget,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/statistics/views/usp_statistics_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import '../../mocks/provider_overrides/mock_statistics.dart';

/// Verifies the E2E identifier hooks added to uspStatistics for PrivacyGUI#1391
/// (unblocks PrivacyGUI-USP-E2E#89): the page-level arrival anchor plus the
/// three NAMED tab hooks (never positional), each locatable via
/// [CommonFinders.bySemanticsIdentifier].
///
/// Deliberately NOT tagged `ui`: this repo's CI runs only `run_tests.sh`
/// (`--exclude-tags=golden||loc||ui`), and the arrival-anchor contract is worth
/// gating there. It mounts the real view — the golden suite lives in a separate
/// repo — with the same lightweight shell the golden framework uses. Assertion
/// shape mirrors `test/components/ui_kit_page_view_test.dart`.
void main() {
  const anchor = 'statistics';
  const tabHooks = <String>[
    'statistics-tab-network',
    'statistics-tab-devices',
    'statistics-tab-system',
  ];

  setUpAll(() {
    // UspTopBar reads package_info during build; stub the platform channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'PrivacyGUI',
            'packageName': 'com.linksys.privacygui',
            'version': '0.0.0',
            'buildNumber': '0',
          };
        }
        return null;
      },
    );
  });

  Widget wrap() {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const UspStatisticsView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...statisticsOverrides(),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  group('uspStatistics identifiers', () {
    testWidgets('the arrival anchor is locatable by identifier',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsIdentifier(anchor),
        findsOneWidget,
        reason: 'the page-level arrival anchor "$anchor" must be locatable',
      );

      handle.dispose();
    });

    testWidgets('every tab carries its named hook, each a distinct node',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // A Material TabBar builds every Tab up front, so all three hooks are
      // present without switching tabs.
      final matched = <Element>{};
      for (final id in tabHooks) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'tab hook "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(tabHooks.length),
          reason: 'the three tab hooks must target distinct widgets');

      handle.dispose();
    });
  });
}

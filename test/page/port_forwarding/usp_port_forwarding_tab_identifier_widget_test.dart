@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import '../../mocks/provider_overrides/mock_port_forwarding.dart';
import '../../mocks/test_data/scenes/port_forwarding_test_data.dart';

/// Verifies that the three Port Forwarding tabs carry the stable E2E
/// identifiers added in issue #1246 and that each is locatable via
/// [CommonFinders.bySemanticsIdentifier].
///
/// This is the fast local proxy for the E2E `byId()` contract (constitution
/// Article XVI): once the identifier reaches the Semantics tree, the CanvasKit
/// → `flt-semantics-identifier` DOM projection is a Flutter-runtime guarantee,
/// so no web round is needed here. It mirrors the #1218 Advanced Settings
/// identifier widget test that covers the sibling entry cards.
///
/// Before this change the tab strip carried no identifier, so the E2E suite
/// (PrivacyGUI-USP-E2E#44) had to click each tab by its localized label — a
/// follow-on to #1172, which only hooked the controls *inside* the tabs.
void main() {
  // Fixed E2E hooks assigned to the three tabs, in tab-strip order.
  const expectedIdentifiers = <String>[
    'port-forwarding-tab-single',
    'port-forwarding-tab-range',
    'port-forwarding-tab-triggering',
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

  // Mirrors the golden framework's shell: ProviderScope + MaterialApp.router so
  // loc(context) and navigation resolve inside the view under test. The page
  // notifier is pinned to a fixed data state so the tab strip renders.
  Widget wrap() {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const UspPortForwardingDetailView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...portForwardingOverrides(dataState()),
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

  group('Port Forwarding tab identifiers', () {
    testWidgets('every tab is locatable by its identifier', (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // A Material TabBar builds every Tab widget up front (not just the
      // selected one), so all three Semantics identifiers are present without
      // needing to switch tabs.
      for (final id in expectedIdentifiers) {
        expect(
          find.bySemanticsIdentifier(id),
          findsOneWidget,
          reason: 'tab "$id" must be locatable by identifier',
        );
      }

      handle.dispose();
    });

    testWidgets('each identifier resolves to exactly one distinct tab node',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Each hook must be unique — the whole point is that E2E can target one
      // specific tab without the "Port Range Forwarding" / "Port Range
      // Triggering" label ambiguity. Assert one match per id and that the
      // three matched elements are all distinct widgets.
      final matched = <Element>{};
      for (final id in expectedIdentifiers) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'tab "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(expectedIdentifiers.length),
          reason: 'the three tab identifiers must target distinct widgets');

      handle.dispose();
    });

    testWidgets('the localized tab label still renders alongside the hook',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Guards against the identifier swap accidentally dropping the visible
      // label. The three English localized strings must still be on screen.
      // NB: `portTriggering` localizes to "Port Range Triggering" (not
      // "Port Triggering") — the near-collision with "Port Range Forwarding"
      // is precisely the fragility the E2E identifiers are meant to retire.
      expect(find.text('Single Port Forwarding'), findsOneWidget);
      expect(find.text('Port Range Forwarding'), findsOneWidget);
      expect(find.text('Port Range Triggering'), findsOneWidget);

      handle.dispose();
    });
  });
}

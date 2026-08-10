@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/advanced_settings/views/usp_advanced_settings_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_common.dart';

/// Verifies that the Advanced Settings entry cards carry the stable E2E
/// identifiers added in issue #1218 and that each is locatable via
/// [CommonFinders.bySemanticsIdentifier].
///
/// This is the fast local proxy for the E2E `byId()` contract (constitution
/// Article XVI): once the identifier reaches the Semantics tree, the CanvasKit
/// → `flt-semantics-identifier` DOM projection is a Flutter-runtime guarantee,
/// so no web round is needed here.
///
/// Both layout branches are exercised: [UspAdvancedSettingsView] renders a
/// [Column] of cards on mobile (`_buildMobileList`, width < 600) and a 2-up
/// grid on desktop (`_buildDesktopGrid`, width > 1240). The identifier wiring
/// lives in the shared `_buildCard`, but covering both widths proves neither
/// responsive branch drops the hook.
void main() {
  // Fixed E2E hooks assigned to the six entry cards, in list order.
  const expectedIdentifiers = <String>[
    'advanced-settings-internet',
    'advanced-settings-local-network',
    'advanced-settings-firewall',
    'advanced-settings-dmz',
    'advanced-settings-port-forwarding',
    'advanced-settings-static-routing',
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
  // loc(context) and context.pushNamed resolve inside the view under test.
  Widget wrap() {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const UspAdvancedSettingsView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: commonOverrides(),
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  for (final layout in const [
    (name: 'mobile', size: Size(480, 900)),
    (name: 'desktop', size: Size(1280, 900)),
  ]) {
    group('Advanced Settings entry identifiers in ${layout.name} layout', () {
      testWidgets('every entry card is locatable by its identifier',
          (tester) async {
        final handle = tester.ensureSemantics();
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        for (final id in expectedIdentifiers) {
          expect(
            find.bySemanticsIdentifier(id),
            findsOneWidget,
            reason: 'entry card "$id" must be locatable by identifier',
          );
        }

        handle.dispose();
      });

      testWidgets('the embedded identifier string reads back verbatim',
          (tester) async {
        final handle = tester.ensureSemantics();
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();

        final semantics = tester.getSemantics(
          find.bySemanticsIdentifier('advanced-settings-dmz'),
        );
        expect(semantics.identifier, 'advanced-settings-dmz');

        handle.dispose();
      });
    });
  }
}

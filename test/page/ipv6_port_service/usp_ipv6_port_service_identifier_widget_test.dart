import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

// Relocated by #1380 (`a4caf569`) when ipv6_port_service entered the page sweep:
// the mock moved to test/mocks/provider_overrides/ and the fixture became a
// composed scene under test/mocks/test_data/scenes/. `ipv6PortServiceOverrides`
// and `dataState` kept their names and signatures, so this is an import change
// and nothing more. See CLAUDE.md on why `_scene_data` is not `_test_data`.
import '../../mocks/provider_overrides/mock_ipv6_port_service.dart';
import '../../mocks/test_data/scenes/ipv6_port_service_scene_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// Verifies the E2E identifier hooks added to uspIpv6PortService for
/// PrivacyGUI#1391 (unblocks PrivacyGUI-USP-E2E#90). The five dialog hooks
/// already existed but were behind an UNHOOKED door (issue B1 lesson); this
/// card hooks the way in — the add button, and per-rule enable/edit/delete
/// keyed by a STABLE description slug (never a positional index).
///
/// Not tagged `ui`: the arrival anchor + the "hook what opens the dialog"
/// contract is worth gating in `run_tests.sh` (this repo's only CI test job,
/// which excludes golden/loc/ui). Mounts the real view with the golden mocks.
void main() {
  const anchor = 'ipv6-port-service';
  const addHook = 'ipv6-rule-add';
  // Derived from the fixture descriptions ("Web Server" → "web-server", etc.)
  // via ruleIdentifierKey — proves the keys are SEMANTIC, not positional.
  const perRuleHooks = <String>[
    'ipv6-rule-enable-web-server',
    'ipv6-rule-edit-web-server',
    'ipv6-rule-delete-web-server',
    'ipv6-rule-enable-game-console',
    'ipv6-rule-edit-game-console',
    'ipv6-rule-delete-game-console',
    'ipv6-rule-enable-ssh-access',
    'ipv6-rule-edit-ssh-access',
    'ipv6-rule-delete-ssh-access',
  ];

  setUpAll(() {
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
          builder: (context, state) => const UspIpv6PortServiceView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...ipv6PortServiceOverrides(dataState()),
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

  group('uspIpv6PortService identifiers', () {
    testWidgets('the arrival anchor is locatable by identifier',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(anchor), findsOneWidget,
          reason: 'the arrival anchor "$anchor" must be locatable');

      handle.dispose();
    });

    testWidgets('the add button that OPENS the rule dialog is hooked',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // B1 lesson: a dialog's five hooks are worthless without a hook on what
      // opens it. This is that hook.
      expect(find.bySemanticsIdentifier(addHook), findsOneWidget,
          reason: 'the add button "$addHook" must be locatable');

      handle.dispose();
    });

    testWidgets(
        'per-rule enable/edit/delete carry stable description-slug keys',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final matched = <Element>{};
      for (final id in perRuleHooks) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'per-rule hook "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(perRuleHooks.length),
          reason: 'every per-rule hook must target a distinct widget — '
              'positional keys would collide across reordered rows');

      handle.dispose();
    });
  });
}

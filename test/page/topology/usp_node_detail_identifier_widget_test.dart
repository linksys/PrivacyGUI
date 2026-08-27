import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import '../../mocks/provider_overrides/mock_topology.dart';
import '../../mocks/test_data/scenes/topology_scene_data.dart';

/// Verifies the E2E identifier hooks added to uspNodeDetail for
/// PrivacyGUI#1391 (unblocks PrivacyGUI-USP-E2E#87): the arrival anchor plus
/// per-connected-device rows keyed by a STABLE MAC slug (never a positional
/// index), so a test can open a specific device from the node.
///
/// Not tagged `ui`: gated in `run_tests.sh` (the repo's only CI test job).
void main() {
  const anchor = 'node-detail';
  // masterNodeWithDevices has two connected clients (MACs …EE:01 / …EE:02);
  // ruleIdentifierKey slugifies the MAC — proves the keys are SEMANTIC.
  const deviceHooks = <String>[
    'node-device-open-aa-bb-cc-dd-ee-01',
    'node-device-open-aa-bb-cc-dd-ee-02',
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
          builder: (context, state) =>
              const UspNodeDetailView(deviceId: '11:22:33:44:55:66'),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...nodeDetailOverrides(masterNodeWithDevices),
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

  group('uspNodeDetail identifiers', () {
    testWidgets('the arrival anchor is locatable by identifier',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      // The node card renders a continuously-loading AppImage.provider, so
      // pumpAndSettle never quiesces; a bounded pump lets the semantics tree
      // build without waiting on the image stream.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.bySemanticsIdentifier(anchor), findsOneWidget,
          reason: 'the arrival anchor "$anchor" must be locatable');

      handle.dispose();
    });

    testWidgets('each connected-device row carries a stable MAC-slug key',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(milliseconds: 300));

      final matched = <Element>{};
      for (final id in deviceHooks) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'device row "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(deviceHooks.length),
          reason: 'each device row must target a distinct widget');

      handle.dispose();
    });
  });
}

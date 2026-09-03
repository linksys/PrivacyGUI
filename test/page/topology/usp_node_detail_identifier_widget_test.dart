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
  // The header's two chips (#1465). Both render *translated* labels and nothing
  // else on the page distinguishes them, so without these hooks a spec asserting
  // the node's role or liveness would have to match on `Master`/`Slave` and
  // `Online`/`Offline` in 26 languages.
  const roleHook = 'node-detail-role';
  const livenessHook = 'node-detail-liveness';

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

    testWidgets(
        'the header role and liveness chips are locatable by identifier',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(milliseconds: 300));

      // Asserted here rather than in the header's own behaviour suite
      // (`usp_node_detail_header_liveness_test.dart`) because an identifier that
      // does not survive into the semantics tree is a *hook* failure, and this is
      // the file that owns the page's hooks. That suite reads the chips through
      // their widgets, which would stay green with the hooks dropped.
      expect(find.bySemanticsIdentifier(roleHook), findsOneWidget,
          reason: 'the role chip hook "$roleHook" must be locatable');
      expect(find.bySemanticsIdentifier(livenessHook), findsOneWidget,
          reason: 'the liveness badge hook "$livenessHook" must be locatable');

      // The state has to be readable *through* the hook, not just next to it:
      // an E2E spec locates the badge by identifier and then asserts on the text
      // inside it. `masterNodeWithDevices` is online (`MasterNode.isOnline`).
      expect(
        find.descendant(
          of: find.bySemanticsIdentifier(livenessHook),
          matching: find.text('Online'),
        ),
        findsOneWidget,
        reason: 'the liveness state must live inside the hooked element',
      );

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

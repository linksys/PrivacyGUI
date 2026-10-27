import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../mocks/provider_overrides/mock_common.dart';
import '../../mocks/provider_overrides/mock_topology.dart';
import '../../mocks/test_data/devices_test_data.dart';
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

  Widget wrap([UspNodeDetailState? state, List<Override> extra = const []]) {
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
        ...nodeDetailOverrides(state ?? masterNodeWithDevices),
        ...extra,
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

  // #1688 item 4. The pen is on the node card's name for the router and for
  // an agent that has a Hosts row to write to. An agent with no row gets no
  // pen, as a client with no row gets none: there is nowhere to write a name.
  group('uspNodeDetail rename pen (#1688 item 4)', () {
    const penHook = 'node-detail-edit-name';

    Future<void> pump(WidgetTester tester, UspNodeDetailState state) async {
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(state));
      // The node card's image keeps loading, so pumpAndSettle never settles.
      await tester.pump(const Duration(milliseconds: 300));
    }

    String? penLabel(WidgetTester tester) => tester
        .widget<AppIconButton>(find.ancestor(
            of: find.bySemanticsIdentifier(penHook),
            matching: find.byType(AppIconButton)))
        .semanticLabel;

    testWidgets('an agent with a Hosts row has a pen labelled Rename node',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        UspNodeDetailState(
          node: DevicesTestData.createWifiSlave(
              hostInstancePath: 'Device.Hosts.Host.3.'),
        ),
      );

      expect(find.bySemanticsIdentifier(penHook), findsOneWidget);
      expect(penLabel(tester), 'Rename node');
      handle.dispose();
    });

    testWidgets('an agent with no Hosts row has no pen', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        UspNodeDetailState(node: DevicesTestData.createWifiSlave()),
      );

      expect(find.bySemanticsIdentifier(penHook), findsNothing);
      handle.dispose();
    });

    // The pen's save writes the agent's own Hosts row, through the same
    // updateIdentity a client's rename uses, with no icon (#1688 item 4).
    testWidgets('saving an agent name writes its Hosts row, with no icon',
        (tester) async {
      final notifier = _RecordingDevicesDataNotifier();
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(
        UspNodeDetailState(
          node: DevicesTestData.createWifiSlave(
              hostInstancePath: 'Device.Hosts.Host.3.'),
        ),
        [devicesDataProvider.overrideWith(() => notifier)],
      ));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.bySemanticsIdentifier('node-detail-edit-name'));
      await tester.pump(const Duration(milliseconds: 300));
      // The dialog has one text field, as its own test finds it.
      await tester.enterText(find.byType(TextField), 'Upstairs');
      // As the dialog's own test taps it: by its localized label.
      final save = lookupAppLocalizations(const Locale('en')).save;
      await tester.tap(find.widgetWithText(AppButton, save));
      await tester.pump(const Duration(milliseconds: 300));

      // Field by field: a record compares its List by identity.
      final call = notifier.calls.single;
      expect(call.hostInstancePaths, ['Device.Hosts.Host.3.']);
      expect(call.name, 'Upstairs');
      expect(call.type, isNull);
    }, semanticsEnabled: true);

    testWidgets('the router keeps its Rename router pen', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, masterNodeWithDevices);

      expect(find.bySemanticsIdentifier(penHook), findsOneWidget);
      expect(penLabel(tester), 'Rename router');
      handle.dispose();
    });
  });
}

/// Records the renames a test triggers, without writing anything.
class _RecordingDevicesDataNotifier extends DevicesDataNotifier {
  final calls =
      <({List<String> hostInstancePaths, String name, String? type})>[];

  @override
  Future<DevicesData> build() async => DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'Test Router'),
        ),
      );

  @override
  Future<void> updateIdentity({
    required List<String> hostInstancePaths,
    required String name,
    String? userTypeCode,
  }) async {
    calls.add(
        (hostInstancePaths: hostInstancePaths, name: name, type: userTypeCode));
  }
}

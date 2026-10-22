import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/services/usp_node_action_service.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/devices_test_data.dart';

class MockUspNodeActionService extends Mock implements UspNodeActionService {}

/// What an agent's Reboot and Factory Reset ask and send (#876), on the
/// daisy chain the ticket's acceptance criteria name: controller, near agent,
/// far agent.
void main() {
  const near = 'AA:BB:CC:DD:EE:0A';
  const far = 'AA:BB:CC:DD:EE:0B';

  late MockUspNodeActionService mockService;

  SlaveNode agent(String mac, String? parent, String name,
          {Set<NodeAction> actions = const {
            NodeAction.reboot,
            NodeAction.factoryReset,
          }}) =>
      DevicesTestData.createWifiSlave(
        deviceId: mac,
        dataElementsId: mac,
        friendlyName: name,
        backhaul: BackhaulInfo(linkType: 'Wi-Fi', parentNodeId: parent),
      ).copyWith(actions: actions);

  MeshNetwork chain({
    String? farParent = near,
    Set<NodeAction> farActions = const {
      NodeAction.reboot,
      NodeAction.factoryReset,
    },
  }) =>
      MeshNetwork(
        master: DevicesTestData.createMaster(),
        slaves: [
          agent(near, DevicesTestData.masterMac, 'Hallway'),
          agent(far, farParent, 'Garage', actions: farActions),
        ],
      );

  /// Fails after a beat, as a real Operate does: `doSomethingWithSpinner`
  /// listens to the task ~100 ms in, so a stub that fails at once is reported
  /// as unhandled — a property of the stub, not of the page (same note in
  /// usp_administration_view_test.dart).
  void failsLater(String deviceId, ServiceError error) {
    when(() => mockService.run(any(), deviceId)).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      throw error;
    });
  }

  setUpAll(() {
    registerFallbackValue(NodeAction.reboot);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async => call.method == 'getAll'
          ? <String, dynamic>{
              'appName': 'PrivacyGUI',
              'packageName': 'com.linksys.privacygui',
              'version': '0.0.0',
              'buildNumber': '0',
            }
          : null,
    );
  });

  setUp(() {
    mockService = MockUspNodeActionService();
    when(() => mockService.run(any(), any())).thenAnswer((_) async {});
  });

  Future<void> open(WidgetTester tester, MeshNetwork network,
      {required String deviceId}) async {
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => UspNodeDetailView(deviceId: deviceId),
        ),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        devicesDataProvider.overrideWith(() =>
            FixedDevicesDataNotifierForTopology(
                DevicesData(meshNetwork: network))),
        uspNodeActionServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: router,
      ),
    ));
    // The node card's image keeps loading, so pumpAndSettle never settles.
    await tester.pump(const Duration(milliseconds: 300));
  }

  // By the button's own identifier rather than through the semantics tree:
  // the confirmation's buttons are not in it while the dialog route animates
  // in, and the identifiers' reach into semantics is the identifier suite's
  // to assert.
  Future<void> tapAction(WidgetTester tester, String hook) async {
    await tester.tap(
        find.byWidgetPredicate((w) => w is AppButton && w.identifier == hook));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> confirmReboot(WidgetTester tester) async {
    await tapAction(tester, 'node-detail-reboot');
    await tapAction(tester, 'admin-confirm-action-confirm');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('UspNodeDetailView - agent node actions (#876)', () {
    testWidgets('the confirmation names every node that goes down, far first',
        (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, chain(), deviceId: near);

      await tapAction(tester, 'node-detail-reboot');

      expect(find.text('Reboot the node and all its child/s'), findsOneWidget);
      expect(
        find.textContaining('the farthest first: Garage, Hallway.'),
        findsOneWidget,
      );
      expect(
          find.textContaining('did not report how they connect'), findsNothing);
      verifyNever(() => mockService.run(any(), any()));
      handle.dispose();
    });

    testWidgets('a node with nothing behind it is confirmed on its own',
        (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, chain(), deviceId: far);

      await tapAction(tester, 'node-detail-factory-reset');

      expect(find.text('Reset to Factory Default'), findsOneWidget);
      expect(
        find.textContaining('Garage returns to factory settings'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('warns when a node may be behind this one unlisted',
        (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, chain(farParent: null), deviceId: near);

      await tapAction(tester, 'node-detail-reboot');

      expect(find.textContaining('did not report how they connect'),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('confirming sends far then near', (tester) async {
      final handle = tester.ensureSemantics();
      final order = <String>[];
      when(() => mockService.run(any(), any())).thenAnswer((inv) async {
        order.add(inv.positionalArguments[1] as String);
      });
      await open(tester, chain(), deviceId: near);

      await tapAction(tester, 'node-detail-reboot');
      await tapAction(tester, 'admin-confirm-action-confirm');
      await tester.pump(const Duration(milliseconds: 300));

      expect(order, [far, near]);
      handle.dispose();
    });

    // A node behind the target that does not run the command goes down
    // with it but is not sent it: sent first, it would refuse and stop the
    // run before the target got the command (FWDEV#202, third-party agents).
    testWidgets('a node behind that cannot run it is named and not sent',
        (tester) async {
      final handle = tester.ensureSemantics();
      final order = <String>[];
      when(() => mockService.run(any(), any())).thenAnswer((inv) async {
        order.add(inv.positionalArguments[1] as String);
      });
      await open(tester, chain(farActions: const {}), deviceId: near);

      await tapAction(tester, 'node-detail-reboot');
      expect(find.text('Reboot Unit'), findsOneWidget);
      expect(
        find.textContaining('are not sent it, but they lose their '
            'connection while the nodes they connect through are down: '
            'Garage.'),
        findsOneWidget,
      );
      await tapAction(tester, 'admin-confirm-action-confirm');
      await tester.pump(const Duration(milliseconds: 300));

      expect(order, [near]);
      handle.dispose();
    });

    // FWDEV#202: a 7022 timeout is not final, because linksys-mesh-sync
    // resends once after the call returned. So the message may not say the
    // node is unchanged, and may not invite an immediate second command.
    testWidgets('an unconfirmed command says the node may still act',
        (tester) async {
      final handle = tester.ensureSemantics();
      failsLater(
        far,
        const UspCompleteFailureError(
            summary: 'refused', failures: [], code: 7022),
      );
      await open(tester, chain(), deviceId: far);

      await confirmReboot(tester);

      expect(
        find.textContaining(
            'Garage did not confirm the command. It may '
            'still act on it',
            findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('try again in a moment', findRichText: true),
          findsNothing);
      handle.dispose();
    });

    testWidgets('a node that left says so and names the nodes already sent',
        (tester) async {
      final handle = tester.ensureSemantics();
      failsLater(near, const ResourceNotFoundError(code: 7016));
      await open(tester, chain(), deviceId: near);

      await confirmReboot(tester);

      expect(
        find.textContaining('Hallway is no longer in your network.',
            findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Already sent to: Garage.', findRichText: true),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  // The router's page runs the Administration page's own flow (decided
  // 2026-10-22), so these read the confirmation it shows. With nodes
  // attached Device.Reboot() takes them down first (FWDEV#202), and the copy
  // says so; on a single router it is the copy the flow always had.
  group('UspNodeDetailView - router actions (#876)', () {
    Future<void> openRouter(WidgetTester tester, MeshNetwork network) =>
        open(tester, network, deviceId: DevicesTestData.masterMac);

    final singleRouter = MeshNetwork(master: DevicesTestData.createMaster());

    testWidgets('a single router keeps the single-router reboot copy',
        (tester) async {
      final handle = tester.ensureSemantics();
      await openRouter(tester, singleRouter);

      await tapAction(tester, 'node-detail-reboot');

      expect(find.text('Reboot Router'), findsOneWidget);
      expect(find.textContaining('The router will restart.'), findsOneWidget);
      await tapAction(tester, 'admin-confirm-action-cancel');
      verifyNever(() => mockService.run(any(), any()));
      handle.dispose();
    });

    testWidgets('a router with nodes says the whole mesh restarts',
        (tester) async {
      final handle = tester.ensureSemantics();
      await openRouter(tester, chain());

      await tapAction(tester, 'node-detail-reboot');

      expect(find.text('Reboot Parent and all its child/s'), findsOneWidget);
      expect(find.textContaining('every node in your mesh restart'),
          findsOneWidget);
      await tapAction(tester, 'admin-confirm-action-cancel');
      handle.dispose();
    });

    testWidgets('a router with nodes says the whole mesh is reset',
        (tester) async {
      final handle = tester.ensureSemantics();
      await openRouter(tester, chain());

      await tapAction(tester, 'node-detail-factory-reset');

      expect(find.text('Reset Parent and all its child/s to Factory Default'),
          findsOneWidget);
      expect(find.textContaining('every node in your mesh return to factory'),
          findsOneWidget);
      await tapAction(tester, 'admin-confirm-action-cancel');
      handle.dispose();
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_menu.dart';
import 'package:privacy_gui/page/topology/services/usp_node_action_service.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/devices_test_data.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart'
    as topology_scene;
import '../../../util/settle.dart';

class MockUspNodeActionService extends Mock implements UspNodeActionService {}

/// Reboot and Factory Reset from the topology's node menu (#876): the same
/// flow the node detail page runs, opened from #1725's menu, on the daisy
/// chain the ticket's acceptance criteria name.
///
/// The tree view (480px), where the menu is a button on the node's row.
void main() {
  const near = 'AA:BB:CC:DD:EE:0A';
  const far = 'AA:BB:CC:DD:EE:0B';

  late MockUspNodeActionService mockService;

  SlaveNode agent(String mac, String parent, String name) =>
      DevicesTestData.createWifiSlave(
        deviceId: mac,
        dataElementsId: mac,
        friendlyName: name,
        hostName: name,
        backhaul: BackhaulInfo(linkType: 'Wi-Fi', parentNodeId: parent),
      ).copyWith(actions: NodeAction.values.toSet());

  final chain = MeshNetwork(
    master: DevicesTestData.createMaster(),
    slaves: [
      agent(near, DevicesTestData.masterMac, 'Hallway'),
      agent(far, near, 'Garage'),
    ],
  );

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

  Future<void> pumpTopology(
    WidgetTester tester, {
    MeshNetwork? network,
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...topologyViewOverrides(
          devicesData: DevicesData(meshNetwork: network ?? chain),
          systemInfoData: topology_scene.testSystemInfoData,
        ),
        uspNodeActionServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        ...extra,
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            LinksysRoute(
              path: '/',
              name: 'topology_host',
              builder: (context, state) => const UspTopologyView(),
            ),
          ],
        ),
      ),
    ));
    await settleIgnoringAnimations(tester);
  }

  /// Opens the menu on the row that shows [name]: the menu button level with
  /// the name, since the kit's tree row puts them side by side.
  Future<void> openMenuOf(WidgetTester tester, String name) async {
    final nameY = tester.getCenter(find.text(name)).dy;
    final buttons = find.byIcon(Icons.more_vert).evaluate().toList()
      ..sort((a, b) => (tester.getCenter(find.byWidget(a.widget)).dy - nameY)
          .abs()
          .compareTo(
              (tester.getCenter(find.byWidget(b.widget)).dy - nameY).abs()));
    await tester.tap(find.byWidget(buttons.first.widget));
    await settleIgnoringAnimations(tester);
  }

  Future<void> tapButton(WidgetTester tester, String identifier) async {
    await tester.tap(find.byWidgetPredicate(
        (w) => w is AppButton && w.identifier == identifier));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('UspTopologyView - node actions from the node menu (#876)', () {
    testWidgets('every mesh node has a menu, and an agent lists its actions',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTopology(tester);

      // The controller and both agents.
      expect(find.byIcon(Icons.more_vert), findsNWidgets(3));

      await openMenuOf(tester, 'Hallway');
      expect(find.bySemanticsIdentifier(kTopologyNodeRebootIdentifier),
          findsOneWidget);
      expect(find.bySemanticsIdentifier(kTopologyNodeFactoryResetIdentifier),
          findsOneWidget);
      expect(find.bySemanticsIdentifier(kTopologyNodeAddNodesIdentifier),
          findsNothing,
          reason: 'Add nodes is the controller\'s only');
      handle.dispose();
    });

    // Each agent's menu is its own X_LINKSYS_SupportedOperations, read off
    // that node: an agent listing nothing (third-party, older firmware) has
    // no menu button beside one that lists both.
    testWidgets('an agent that lists nothing has no menu beside one that does',
        (tester) async {
      await pumpTopology(
        tester,
        network: MeshNetwork(
          master: DevicesTestData.createMaster(),
          slaves: [
            agent(near, DevicesTestData.masterMac, 'Hallway'),
            agent(far, near, 'Garage').copyWith(actions: const {}),
          ],
        ),
      );

      // The controller and Hallway; not Garage.
      expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
    });

    testWidgets(
        'Reboot on an agent confirms the nodes behind it, sends far then near, '
        'and stays on the topology', (tester) async {
      final handle = tester.ensureSemantics();
      final order = <String>[];
      when(() => mockService.run(any(), any())).thenAnswer((inv) async {
        order.add(inv.positionalArguments[1] as String);
      });
      await pumpTopology(tester);

      await openMenuOf(tester, 'Hallway');
      await tester.tap(find.text('Reboot'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Reboot the node and all its child/s'), findsOneWidget);
      expect(find.textContaining('the farthest first: Garage, Hallway.'),
          findsOneWidget);

      await tapButton(tester, 'admin-confirm-action-confirm');

      expect(order, [far, near]);
      expect(find.byType(UspTopologyView), findsOneWidget,
          reason:
              'the topology is where the nodes drop off; it does not leave');
      expect(find.text('below the topology'), findsNothing);
      handle.dispose();
    });

    testWidgets('Cancel sends nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTopology(tester);

      await openMenuOf(tester, 'Garage');
      await tester.tap(find.text('Factory Reset'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Garage returns to factory settings'),
          findsOneWidget);
      await tapButton(tester, 'admin-confirm-action-cancel');

      verifyNever(() => mockService.run(any(), any()));
      handle.dispose();
    });

    // The router's Reboot runs the Administration page's flow, whose recovery
    // dialog must still open when the topology's data reloads meanwhile, as a
    // pull to refresh or a push does. Measured here, not assumed: a reload
    // keeps the previous value on screen (`AsyncValue.when` skips loading on a
    // reload), so the data branch and the context the flow holds stay mounted.
    testWidgets(
        'the router\'s Reboot still opens recovery when the topology reloads',
        (tester) async {
      final handle = tester.ensureSemantics();
      final recoveries = <RecoveryContext>[];
      final rebooting = Completer<void>();
      Completer<DevicesData>? reloading;
      await pumpTopology(tester, extra: [
        devicesDataProvider.overrideWith(() => _ReloadableDevicesDataNotifier(
            DevicesData(meshNetwork: chain), () => reloading?.future)),
        uspAdminProvider.overrideWith(() => _RebootingAdminNotifier(rebooting)),
        appConnectionStateProvider
            .overrideWith(() => _RecordingConnectionNotifier(recoveries)),
      ]);
      final container = ProviderScope.containerOf(
          tester.element(find.byType(UspTopologyView)));

      await openMenuOf(tester, 'Linksys-Router');
      await tester.tap(find.text('Reboot'));
      await tester.pump(const Duration(milliseconds: 300));
      await tapButton(tester, 'admin-confirm-action-confirm');

      // The reboot is in flight; the topology's data reloads and is still
      // loading when the reboot answers.
      reloading = Completer<DevicesData>();
      container.invalidate(devicesDataProvider);
      await tester.pump();
      expect(container.read(devicesDataProvider).isLoading, isTrue,
          reason: 'the reload is held, so the reboot answers during it');
      expect(find.byType(AppTopology), findsOneWidget,
          reason: 'a reload keeps the topology on screen');
      rebooting.complete();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(recoveries.map((r) => r.trigger),
          [RecoveryTrigger.operationalReboot]);
      handle.dispose();
    });

    // The router's Factory Reset from the topology goes to the same seam the
    // Administration page's does, `UspAdminNotifier.factoryReset`, whose guard
    // refuses it in Remote Assistance (`credentialLoss`; pinned in
    // usp_admin_notifier_test.dart and the destructive-operation roster).
    // What this pins is the route to that seam, not the guard again.
    testWidgets('the router\'s Factory Reset goes through the guarded seam',
        (tester) async {
      final handle = tester.ensureSemantics();
      final admin = _RecordingAdminNotifier();
      await pumpTopology(tester, extra: [
        uspAdminProvider.overrideWith(() => admin),
        appConnectionStateProvider
            .overrideWith(() => _RecordingConnectionNotifier([])),
      ]);

      await openMenuOf(tester, 'Linksys-Router');
      await tester.tap(find.text('Factory Reset'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Reset Parent and all its child/s to Factory Default'),
          findsOneWidget,
          reason: 'this fixture\'s mesh is the chain, so the router has nodes '
              'and the whole-mesh title is expected');
      await tapButton(tester, 'admin-confirm-action-confirm');

      expect(admin.calls, ['factoryReset']);
      verifyNever(() => mockService.run(any(), any()));
      handle.dispose();
    });
  });
}

/// Reboots once [rebooting] completes; never finishes loading, because the
/// flow reads none of its state.
class _RebootingAdminNotifier extends UspAdminNotifier {
  _RebootingAdminNotifier(this.rebooting);

  final Completer<void> rebooting;

  @override
  Future<UspAdminState> build() => Completer<UspAdminState>().future;

  @override
  Future<void> reboot() => rebooting.future;
}

/// Records every recovery the flow asks for and declines it, so the test can
/// see that it was asked for without a dialog to drive.
class _RecordingConnectionNotifier extends AppConnectionStateNotifier {
  _RecordingConnectionNotifier(this.calls);

  final List<RecoveryContext> calls;

  @override
  bool enterWaiting({required RecoveryContext context}) {
    calls.add(context);
    return false;
  }
}

/// [data] on the first build; after that, whatever [next] hands back, so a
/// test can hold a reload in its loading state.
class _ReloadableDevicesDataNotifier extends DevicesDataNotifier {
  _ReloadableDevicesDataNotifier(this.data, this.next);

  final DevicesData data;
  final Future<DevicesData>? Function() next;
  var _builds = 0;

  @override
  Future<DevicesData> build() async {
    if (_builds++ == 0) return data;
    return await (next() ?? Future.value(data));
  }
}

/// Records which router operation the flow asked for, and answers it.
class _RecordingAdminNotifier extends UspAdminNotifier {
  final calls = <String>[];

  @override
  Future<UspAdminState> build() => Completer<UspAdminState>().future;

  @override
  Future<void> reboot() async => calls.add('reboot');

  @override
  Future<void> factoryReset() async => calls.add('factoryReset');
}

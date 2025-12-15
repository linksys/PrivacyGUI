import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/instant_topology/views/instant_topology_view.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';

import '../../../common/config.dart';
import '../../../common/screen.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/topology_data.dart';

// View ID: ITOP
// Implementation: lib/page/instant_topology/views/instant_topology_view.dart
/// | Test ID             | Description                                                                   |
/// | :------------------ | :---------------------------------------------------------------------------- |
/// | `ITOP-LAYOUT`       | Base star topology renders Internet header, master, and child nodes.          |
/// | `ITOP-ACTIONS`      | Master instant-action menu exposes blink, reboot, pair, and reset controls.   |
/// | `ITOP-OFFLINE`      | Tapping an offline node surfaces the troubleshooting modal with guidance.     |
/// | `ITOP-FW`           | Nodes with pending firmware show the “Update available” indicator with CTA.   |
/// | `ITOP-PAIRING`      | Wired pairing dialog shows progress state while auto-onboarding runs.         |
/// | `ITOP-PAIR_SUCCESS` | Wired pairing dialog shows completion state when nodes are onboarded.         |
/// | `ITOP-PAIR_EMPTY`   | Wired pairing dialog shows “not found” completion when no nodes detected.     |

final _desktopTallScreens =
    responsiveDesktopScreens.map((screen) => screen.copyWith(height: 1600)).toList();
final _topologyScreens = [
  ...responsiveMobileScreens.map((screen) => screen.copyWith(height: 1280)),
  ..._desktopTallScreens,
];

InstantTopologyState _defaultTopologyState() =>
    TopologyTestData().testTopology2SlavesStarState;

Future<void> _precacheTopologyImages(WidgetTester tester) async {
  final context = tester.element(find.byType(InstantTopologyView));
  final theme = CustomTheme.of(context);
  final images = {
    theme.images.devices.routerLn12,
    theme.images.devices.routerMx5300,
    theme.images.devices_xl.routerLn12,
  };
  for (final image in images) {
    await precacheImage(image, context);
  }
}

Future<void> _openPairWiredDialog(WidgetTester tester) async {
  final masterAction =
      find.byType(PopupMenuButton<NodeInstantActions>).first;
  await tester.tap(masterAction);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('popup-menu-pair')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('popup-sub-menu-pairWired')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    initBetterActions();
    when(testHelper.mockServiceHelper.isSupportAutoOnboarding())
        .thenReturn(true);
    when(testHelper.mockServiceHelper.isSupportLedBlinking()).thenReturn(true);
    when(testHelper.mockServiceHelper.isSupportChildFactoryReset())
        .thenReturn(true);
    when(testHelper.mockServiceHelper.isSupportChildReboot()).thenReturn(true);
  });

  Future<BuildContext> pumpInstantTopology(
    WidgetTester tester,
    LocalizedScreen screen, {
    InstantTopologyState? state,
    List<Override> overrides = const [],
  }) async {
    when(testHelper.mockInstantTopologyNotifier.build())
        .thenReturn(state ?? _defaultTopologyState());

    final context = await testHelper.pumpView(
      tester,
      overrides: overrides,
      child: const InstantTopologyView(),
      locale: screen.locale,
    );
    await tester.runAsync(() async {
      await _precacheTopologyImages(tester);
    });
    await tester.pumpAndSettle();
    return context;
  }

  // Test ID: ITOP-LAYOUT — base topology grid renders nodes and actions
  testLocalizationsV2(
    'instant topology view - base tree layout',
    (tester, screen) async {
      final topologyState = TopologyTestData().testTopology5SlavesStarState;
      final context = await pumpInstantTopology(
        tester,
        screen,
        state: topologyState,
      );
      final loc = testHelper.loc(context);

      expect(find.text(loc.instantTopology), findsOneWidget);
      expect(find.text(loc.internet), findsOneWidget);
      expect(find.text('Living room'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
      // expect(find.byType(TopologyNodeItem), findsWidgets);
      expect(find.text(loc.instantAction), findsWidgets);
    },
    screens: _topologyScreens,
    goldenFilename: 'ITOP-LAYOUT-01-tree',
    helper: testHelper,
  );

  // Test ID: ITOP-ACTIONS — verify master instant-action menu entries
  testLocalizationsV2(
    'instant topology view - master action menu',
    (tester, screen) async {
      final context = await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1SlaveState,
      );
      final loc = testHelper.loc(context);

      final actionButton =
          find.byType(PopupMenuButton<NodeInstantActions>).first;
      await tester.tap(actionButton);
      await tester.pumpAndSettle();

      expect(find.text(loc.blinkDeviceLight), findsOneWidget);
      expect(find.text(loc.rebootUnit), findsOneWidget);
      expect(find.text(loc.instantPair), findsOneWidget);
      expect(find.text(loc.resetToFactoryDefault), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('popup-menu-pair')));
      await tester.pumpAndSettle();
      expect(find.text(loc.pairWiredNode), findsOneWidget);
      expect(find.text(loc.pairWirelessNode), findsOneWidget);

      await testHelper.takeScreenshot(tester, 'ITOP-ACTIONS-01-menu');
    },
    screens: _desktopTallScreens,
    helper: testHelper,
  );

  // Test ID: ITOP-OFFLINE — offline node modal with troubleshooting steps
  testLocalizationsV2(
    'instant topology view - offline node modal',
    (tester, screen) async {
      final context = await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1OfflineState,
      );
      final loc = testHelper.loc(context);

      final offlineNode = find.text('Kitchen').first;
      await tester.ensureVisible(offlineNode);
      await tester.tap(offlineNode);
      await tester.pumpAndSettle();

      expect(find.text(loc.modalOfflineNodeTitle), findsOneWidget);
      expect(find.text(loc.modalOfflineRemoveNodeFromNetwork), findsOneWidget);
      expect(find.text(loc.close), findsWidgets);

      await testHelper.takeScreenshot(tester, 'ITOP-OFFLINE-01-dialog');
    },
    screens: _desktopTallScreens,
    helper: testHelper,
  );

  // Test ID: ITOP-FW — firmware update indicator on master node
  testLocalizationsV2(
    'instant topology view - firmware update banner',
    (tester, screen) async {
      final context = await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology2SlavesDaisyAndFwUpdateState,
      );
      final loc = testHelper.loc(context);

      expect(find.text(loc.updateAvailable), findsWidgets);
      expect(find.text('Living room 1'), findsOneWidget);

      await testHelper.takeScreenshot(tester, 'ITOP-FW-01-indicator');
    },
    screens: _desktopTallScreens,
    helper: testHelper,
  );

  // Test ID: ITOP-PAIRING — wired pairing dialog shows progress state
  testLocalizationsV2(
    'instant topology view - wired pairing progress dialog',
    (tester, screen) async {
      final context = await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1SlaveState,
        overrides: [
          addWiredNodesProvider
              .overrideWith(() => _ProcessingAddWiredNodesNotifier()),
        ],
      );
      final loc = testHelper.loc(context);

      await _openPairWiredDialog(tester);

      expect(find.text(loc.instantPair), findsNWidgets(2));
      expect(find.text(loc.pairingWiredChildNodeDesc), findsOneWidget);
      expect(find.text(loc.donePairing), findsOneWidget);

      await testHelper.takeScreenshot(tester, 'ITOP-PAIRING-01-dialog');
    },
    screens: _desktopTallScreens,
    helper: testHelper,
  );

  // Test ID: ITOP-PAIR_SUCCESS — wired pairing completes with onboarded nodes
  testLocalizationsV2(
    'instant topology view - wired pairing success dialog',
    (tester, screen) async {
      final context = await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1SlaveState,
        overrides: [
          addWiredNodesProvider
              .overrideWith(() => _SuccessAddWiredNodesNotifier()),
        ],
      );
      final loc = testHelper.loc(context);

      await _openPairWiredDialog(tester);

      expect(find.text(loc.wiredPairComplete), findsOneWidget);
      expect(find.text(loc.foundNNodesOnline(1)), findsOneWidget);
      expect(find.text(loc.donePairing), findsOneWidget);

      await testHelper.takeScreenshot(
        tester,
        'ITOP-PAIR_SUCCESS-01-dialog',
      );
    },
    screens: _desktopTallScreens,
    helper: testHelper,
  );

  // Test ID: ITOP-PAIR_EMPTY — wired pairing completes without new nodes
  testLocalizationsV2(
    'instant topology view - wired pairing no nodes dialog',
    (tester, screen) async {
      final context = await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1SlaveState,
        overrides: [
          addWiredNodesProvider
              .overrideWith(() => _NoNewNodesAddWiredNodesNotifier()),
        ],
      );
      final loc = testHelper.loc(context);

      await _openPairWiredDialog(tester);

      expect(find.text(loc.wiredPairCompleteNotFound), findsOneWidget);
      expect(find.text(loc.donePairing), findsOneWidget);

      await testHelper.takeScreenshot(
        tester,
        'ITOP-PAIR_EMPTY-01-dialog',
      );
    },
    screens: _desktopTallScreens,
    helper: testHelper,
  );
}

class _ProcessingAddWiredNodesNotifier extends AddWiredNodesNotifier {
  @override
  AddWiredNodesState build() => const AddWiredNodesState(isLoading: false);

  @override
  Future startAutoOnboarding(BuildContext context) async {
    state = const AddWiredNodesState(
      isLoading: true,
      onboardingProceed: false,
    );
  }
}

class _SuccessAddWiredNodesNotifier extends AddWiredNodesNotifier {
  @override
  AddWiredNodesState build() => const AddWiredNodesState(isLoading: false);

  @override
  Future startAutoOnboarding(BuildContext context) async {
    state = AddWiredNodesState(
      isLoading: false,
      onboardingProceed: true,
      anyOnboarded: true,
      loadingMessage: loc(context).foundNNodesOnline(1),
    );
  }
}

class _NoNewNodesAddWiredNodesNotifier extends AddWiredNodesNotifier {
  @override
  AddWiredNodesState build() => const AddWiredNodesState(isLoading: false);

  @override
  Future startAutoOnboarding(BuildContext context) async {
    state = const AddWiredNodesState(
      isLoading: false,
      onboardingProceed: true,
      anyOnboarded: false,
    );
  }
}

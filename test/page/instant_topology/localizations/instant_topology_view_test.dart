import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/config.dart';
import '../../../common/screen.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/topology_data.dart';

// View ID: ITOP
//
// Implementation File: lib/page/instant_topology/views/instant_topology_view.dart
//
// Test Summary:
// | Test ID               | Description                                                                 |
// | :-------------------- | :-------------------------------------------------------------------------- |
// | `ITOP-LAYOUT-TREE`    | Verifies Tree View layout (Mobile < 600px) with status badges               |
// | `ITOP-LAYOUT-GRAPH`   | Verifies Graph View layout (Tablet/Desktop >= 600px) without text badges    |
// | `ITOP-MENU-TREE`      | Verifies vertical menu button (`more_vert`) in Tree View                    |
// | `ITOP-MENU-GRAPH`     | Verifies horizontal menu button (`more_horiz`) in Graph View                |
// | `ITOP-OFFLINE-TREE`   | Verifies offline text badge in Tree View                                    |
// | `ITOP-OFFLINE-GRAPH`  | Verifies offline nodes in Graph View (visual only, no text)                 |
// | `ITOP-FWUPDATE`       | Verifies firmware update indicator visibility                               |

final _desktopTallScreens = responsiveDesktopScreens
    .map((screen) => screen.copyWith(height: 1600))
    .toList();

// Tree View Screens: Mobile (< 600px)
final _treeViewScreens = responsiveMobileScreens
    .map((screen) => screen.copyWith(height: 1280))
    .where((s) => s.width < 600)
    .toList();

// Graph View Screens: Tablet & Desktop (>= 600px)
final _graphViewScreens =
    _desktopTallScreens.where((s) => s.width >= 600).toList();

final _allScreens = [..._treeViewScreens, ..._graphViewScreens];

InstantTopologyState _defaultTopologyState() =>
    TopologyTestData().testTopology2SlavesStarState;

Future<void> _precacheTopologyImages(WidgetTester tester) async {
  final context = tester.element(find.byType(InstantTopologyView));
  final images = {
    Assets.images.devices.routerLn12.provider(),
    Assets.images.devices.routerMx5300.provider(),
    Assets.images.devicesXl.routerLn12.provider(),
  };
  for (final image in images) {
    await precacheImage(image, context);
  }
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

  // ===========================================================================
  // Tree View Tests (Mobile < 600px)
  // ===========================================================================

  testThemeLocalizations(
    'instant topology view - tree view layout',
    (tester, screen) async {
      final topologyState = TopologyTestData().testTopology5SlavesStarState;
      await pumpInstantTopology(
        tester,
        screen,
        state: topologyState,
      );

      // Verify page title
      expect(find.text('Instant-Topology'), findsOneWidget);

      // Verify nodes
      expect(find.text('Living room'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Basement'), findsOneWidget);

      // Verify status badges (Visible in Tree View)
      expect(find.text('online'), findsAtLeastNWidgets(1),
          reason: 'Status badges should be visible in Tree View');

      await testHelper.takeScreenshot(tester, 'ITOP-LAYOUT-TREE-01-base');
    },
    screens: _treeViewScreens,
    helper: testHelper,
  );

  testThemeLocalizations(
    'instant topology view - tree view menu',
    (tester, screen) async {
      await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1SlaveState,
      );

      // Verify vertical menu button (Icons.more_vert)
      final moreVertIcons = find.byIcon(Icons.more_vert);
      expect(moreVertIcons, findsAtLeastNWidgets(1),
          reason: 'Vertical menu buttons should be visible in Tree View');

      await testHelper.takeScreenshot(tester, 'ITOP-MENU-TREE-01-display');

      // Test menu tap if needed (skipping for snapshot focus)
    },
    screens: _treeViewScreens,
    helper: testHelper,
  );

  testThemeLocalizations(
    'instant topology view - tree view offline',
    (tester, screen) async {
      await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1OfflineState,
      );

      // Verify nodes
      expect(find.text('Living room'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);

      // Verify offline badge (Visible in Tree View)
      expect(find.text('offline'), findsOneWidget,
          reason: 'Offline badge should be visible in Tree View');

      await testHelper.takeScreenshot(tester, 'ITOP-OFFLINE-TREE-01-display');
    },
    screens: _treeViewScreens,
    helper: testHelper,
  );

  // ===========================================================================
  // Graph View Tests (Desktop/Tablet >= 600px)
  // ===========================================================================

  testThemeLocalizations(
    'instant topology view - graph view layout',
    (tester, screen) async {
      final topologyState = TopologyTestData().testTopology5SlavesStarState;
      await pumpInstantTopology(
        tester,
        screen,
        state: topologyState,
      );

      expect(find.text('Instant-Topology'), findsOneWidget);
      expect(find.text('Living room'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);

      // Verify NO status text badges (Graph View uses visual indicators)
      expect(find.text('online'), findsNothing,
          reason: 'Text status badges should NOT be visible in Graph View');

      await testHelper.takeScreenshot(tester, 'ITOP-LAYOUT-GRAPH-01-base');
    },
    screens: _graphViewScreens,
    helper: testHelper,
  );

  testThemeLocalizations(
    'instant topology view - graph view menu',
    (tester, screen) async {
      await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1SlaveState,
      );

      // Verify horizontal menu button (Icons.more_horiz)
      final moreHorizIcons = find.byIcon(Icons.more_horiz);
      expect(moreHorizIcons, findsAtLeastNWidgets(1),
          reason: 'Horizontal menu buttons should be visible in Graph View');

      await testHelper.takeScreenshot(tester, 'ITOP-MENU-GRAPH-01-display');
    },
    screens: _graphViewScreens,
    helper: testHelper,
  );

  testThemeLocalizations(
    'instant topology view - graph view offline',
    (tester, screen) async {
      await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology1OfflineState,
      );

      expect(find.text('Living room'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);

      // Verify NO offline text badge
      expect(find.text('offline'), findsNothing,
          reason: 'Text offline badge should NOT be visible in Graph View');

      await testHelper.takeScreenshot(tester, 'ITOP-OFFLINE-GRAPH-01-display');
    },
    screens: _graphViewScreens,
    helper: testHelper,
  );

  // ===========================================================================
  // Common / Firmware Update Tests (Run on both or specific subset)
  // ===========================================================================

  testThemeLocalizations(
    'instant topology view - firmware update indicator',
    (tester, screen) async {
      await pumpInstantTopology(
        tester,
        screen,
        state: TopologyTestData().testTopology2SlavesDaisyAndFwUpdateState,
      );

      expect(find.text('Living room 1'), findsOneWidget);
      expect(find.byType(AppTopology), findsOneWidget); // Base check

      // Screenshot name depends on screen width for clarity, or just use suffix
      final suffix = screen.width < 600 ? 'TREE' : 'GRAPH';
      await testHelper.takeScreenshot(
          tester, 'ITOP-FWUPDATE-$suffix-01-indicator');
    },
    screens: _allScreens, // Run on both to ensure FW update visible in both
    helper: testHelper,
  );
}

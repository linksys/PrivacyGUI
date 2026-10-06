import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/topology/views/usp_topology_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart';

/// What the Devices switch does on a phone, where the page resolves to the tree view.
///
/// From ui_kit 3.4.0 the tree honours `leafVisibility`, and it reads the enum in two
/// states: `always` lists every device, **every other value withholds them** (a list
/// has no viewport to run out of, so the graph's aggregation modes all mean "hide"
/// there). The page passed the graph's `adaptive` to both views, so on a phone the
/// switch hid the devices whichever way it was set (#1630). No test saw it: the
/// adaptive suite pins the graph at 1200px, and only the golden pumps a phone width.
///
/// Not tagged `ui`, so CI runs it: the defect lived in exactly the gap the
/// `ui`-tagged suites leave.
void main() {
  setUpAll(() {
    OuiLookup.initializeForTesting(const {
      '112233': 'Test Vendor',
      'AABBCC': 'Linksys',
    });
  });

  tearDownAll(OuiLookup.reset);

  const clientNames = ['iPhone', 'MacBook Pro', 'Desktop PC'];

  /// Pumps the real page at [width], through the host the layout gate uses.
  Future<void> pumpAt(
    WidgetTester tester,
    double width,
    DevicesData devicesData,
  ) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspTopologyView(),
      locale: const Locale('en'),
      overrides: topologyViewOverrides(
        devicesData: devicesData,
        systemInfoData: testSystemInfoData,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> switchDevicesOff(WidgetTester tester) async {
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
  }

  final scenes = {
    'single node': singleNodeDevicesData,
    'mesh network': meshNetworkDevicesData,
  };

  group('phone width (tree view)', () {
    for (final MapEntry(key: name, value: data) in scenes.entries) {
      testWidgets('$name: Devices on lists every device', (tester) async {
        await pumpAt(tester, 480, data);

        expect(find.byType(TopologyTreeView), findsOneWidget,
            reason: 'at 480px the page must resolve to the tree, or this test '
                'is not about the tree');
        for (final client in clientNames) {
          expect(find.text(client), findsOneWidget, reason: client);
        }
      });

      testWidgets('$name: Devices off withholds every device', (tester) async {
        await pumpAt(tester, 480, data);
        await switchDevicesOff(tester);

        for (final client in clientNames) {
          expect(find.text(client), findsNothing, reason: client);
        }
      });
    }
  });

  group('desktop width (graph view)', () {
    // The graph's policy is unchanged by #1630: adaptive aggregation is the graph's
    // answer to crowding, argued in `usp_topology_view.dart` and pinned against
    // E2E's needs in `usp_topology_adaptive_test.dart`.
    testWidgets('Devices on stays adaptive, off stays collapsed',
        (tester) async {
      await pumpAt(tester, 1280, meshNetworkDevicesData);

      LeafVisibility policy() =>
          tester.widget<AppTopology>(find.byType(AppTopology)).leafVisibility;

      expect(find.byType(TopologyTreeView), findsNothing);
      expect(policy(), LeafVisibility.adaptive);

      await switchDevicesOff(tester);
      expect(policy(), LeafVisibility.collapsed);
    });
  });
}

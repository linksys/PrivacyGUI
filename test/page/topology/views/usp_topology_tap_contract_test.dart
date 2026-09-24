library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:privacy_gui/page/topology/views/components/node_detail_popup.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/devices_test_data.dart';

/// What a tap on a topology node is allowed to do, pinned against the widget
/// rather than against our reading of the kit.
///
/// Both facts here were behaviour the kit changed under us, and neither shows up
/// as a compile error or a failing golden — the page still renders, the tap still
/// works, it just now does two things where it did one:
///
/// 1. **One reaction per tap.** `onNodeTap` used to be the *alternative* to the
///    kit's own detail panel; from ui_kit 3.4.0 it fires unconditionally and the
///    panel opens as well. A page that navigates from `onNodeTap` while also
///    configuring `nodeDetailConfig` therefore navigates *and* opens a panel over
///    the page it is leaving.
/// 2. **A leaf gets no role it does not have.** The kit used to refuse the panel
///    for leaf and external nodes; from 3.4.0 it opens one for any node the
///    consumer configured a panel for. [NodeDetailPopup] was written for mesh
///    nodes and its first row read `isMaster` with no guard, so a laptop was
///    printed as a `Slave`. The row is now gated on the metadata actually
///    carrying a role.
///
/// Both are asserted on [UspTopologyBuilder]'s real output: a leaf built by
/// production code is the input that decides whether the row is a lie.
void main() {
  const sysInfo = SystemInfoUIModel(
    manufacturer: 'Linksys',
    modelName: 'MR7500',
    hardwareVersion: '1.0',
    serialNumber: 'SN123456',
    softwareVersion: '1.0.16.26013014',
    uptime: 3600,
    totalMemory: 512000,
    freeMemory: 256000,
    cpuUsage: 25,
  );

  setUpAll(() {
    OuiLookup.initializeForTesting(const {
      '112233': 'Test Vendor',
      'AABBCC': 'Linksys',
    });
  });

  tearDownAll(OuiLookup.reset);

  GraphData buildTopology() => UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMultiSlaveMeshNetwork(),
        info: sysInfo,
      );

  group('a leaf carries none of NodeDetailPopup\'s role fields', () {
    test('production metadata has no role, and no field the popup prints', () {
      final topology = buildTopology();
      final client = topology.nodes.firstWhere((n) => n.styleSlot == 'leaf');

      // The popup's first row is unconditional and reads `isMaster`, so a node
      // without it is printed as a Slave. Every other row is `if`-guarded on a
      // field this metadata also lacks, which is why the panel for a client is
      // one wrong row and nothing else.
      final metadata = client.metadata!;
      expect(metadata.containsKey('isMaster'), isFalse,
          reason: 'a client has no master/slave role to report');
      for (final key in const [
        'deviceId',
        'model',
        'manufacturer',
        'serialNumber',
        'softwareVersion',
        'backhaulLinkType',
        'backhaulSignalStrength',
        'backhaulUplinkRate',
        'backhaulDownlinkRate',
      ]) {
        expect(metadata.containsKey(key), isFalse,
            reason: '$key is an infrastructure-node field');
      }
    });

    testWidgets('so the popup prints no role for it', (tester) async {
      final topology = buildTopology();
      final client = topology.nodes.firstWhere((n) => n.styleSlot == 'leaf');

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NodeDetailPopup(node: client, metadata: client.metadata),
        ),
      ));
      await tester.pumpAndSettle();

      // Neither word: a leaf has no master/slave role, and the row that would
      // print one is gated on the metadata carrying `isMaster` at all. Before the
      // guard, `?? false` made this node print `Slave`.
      expect(find.text('Slave'), findsNothing);
      expect(find.text('Master'), findsNothing);
    });
  });

  group('one reaction per tap', () {
    testWidgets(
        'tapping a client both reports to onNodeTap and opens the panel',
        (tester) async {
      final topology = buildTopology();
      final client = topology.nodes.firstWhere((n) => n.styleSlot == 'leaf');
      final reported = <String>[];
      var panelBuilt = 0;

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.create(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 900,
            // The production pairing from usp_topology_view.dart: a navigating
            // `onNodeTap` alongside a tap-triggered `nodeDetailConfig`.
            child: AppTopology(
              topology: topology,
              viewMode: TopologyViewMode.graph,
              leafVisibility: LeafVisibility.always,
              nodeRendererRegistry: NodeRendererRegistry.unified,
              enableAnimation: false,
              interactive: false,
              onNodeTap: reported.add,
              nodeDetailConfig: NodeDetailConfig(
                trigger: NodeDetailTrigger.tap,
                mode: NodeDetailMode.floatingPanel,
                detailBuilder: (ctx, node, metadata) {
                  panelBuilt++;
                  return const SizedBox(width: 320, height: 200);
                },
              ),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));

      final target = find.bySemanticsIdentifier(
        RegExp('^${RegExp.escape(client.identifier!)}\$'),
      );
      expect(target, findsWidgets,
          reason: 'the client node must be locatable to tap it');
      await tester.tap(target.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      // Both fired. In production the first navigates away and the second opens
      // a panel on the page being left.
      expect(reported, [client.id]);
      expect(panelBuilt, greaterThan(0),
          reason: 'ui_kit 3.4.0 no longer withholds the panel from a leaf');
    });
  });
}

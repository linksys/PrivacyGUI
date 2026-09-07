@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/devices_test_data.dart';

/// Verifies that the `identifier` values populated by [UspTopologyBuilder]
/// (issue #1208) are embedded into the Semantics tree and locatable via
/// [CommonFinders.bySemanticsIdentifier] in BOTH view modes.
///
/// This is the fast local proxy for the E2E `byIdentifier()` contract — the
/// CanvasKit → `flt-semantics-identifier` DOM projection is a Flutter-runtime
/// guarantee once the identifier exists, so it needs no web round here.
///
/// Coverage note: from ui_kit `v2.34.2`, identifier ownership sits on the
/// node-dispatch seam (not per-renderer), so EVERY node type — master, slave
/// AND client — carries its identifier in both graph and tree view,
/// independent of which renderer the registry happens to dispatch.
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

  // Mirrors the production config in usp_topology_view.dart: animation path on.
  Widget wrap(MeshTopology topology, TopologyViewMode mode) {
    return MaterialApp(
      theme: AppTheme.create(brightness: Brightness.light),
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 900,
          child: AppTopology(
            topology: topology,
            viewMode: mode,
            clientVisibility: ClientVisibility.always,
            nodeRendererRegistry: NodeRendererRegistry.unified,
            enableAnimation: true,
            interactive: false,
            treeConfig: TopologyTreeConfiguration(
              titleBuilder: (node) => node.name,
              subtitleBuilder: (node) => node.extra ?? '',
              preferAnimationNode: true,
              expanded: true,
            ),
          ),
        ),
      ),
    );
  }

  // Every node type (master + slave + client) must be locatable by identifier
  // in BOTH view modes — the core #1208 requirement, guaranteed by the ui_kit
  // v2.34.2 node-dispatch seam.
  for (final mode in [TopologyViewMode.graph, TopologyViewMode.tree]) {
    group('node identifiers locatable in ${mode.name} view', () {
      testWidgets('master, every slave and every client carry an identifier',
          (tester) async {
        final handle = tester.ensureSemantics();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: DevicesTestData.createMultiSlaveMeshNetwork(),
          info: sysInfo,
        );

        await tester.pumpWidget(wrap(topology, mode));
        await tester.pump(const Duration(milliseconds: 500));

        // Master locatable by its fixed identifier.
        expect(
            find.bySemanticsIdentifier('topology-node-master'), findsOneWidget);

        // Each slave locatable by its data-derived identifier
        // (slaveMac1 = ...EE:01, slaveMac2 = ...EE:02 → unique at 4 hex).
        expect(find.bySemanticsIdentifier('topology-node-slave-EE01'),
            findsOneWidget);
        expect(find.bySemanticsIdentifier('topology-node-slave-EE02'),
            findsOneWidget);

        // Each client locatable by its data-derived identifier
        // (client MACs 11:22:33:44:55:0X → unique at 4 hex).
        expect(find.bySemanticsIdentifier('topology-node-client-5501'),
            findsOneWidget);
        expect(find.bySemanticsIdentifier('topology-node-client-5503'),
            findsOneWidget);
        expect(find.bySemanticsIdentifier('topology-node-client-5504'),
            findsOneWidget);

        handle.dispose();
      });

      testWidgets('the embedded identifier string reads back verbatim',
          (tester) async {
        final handle = tester.ensureSemantics();

        final topology = UspTopologyBuilder.buildFromMeshNetwork(
          meshNetwork: DevicesTestData.createSingleNodeNetwork(),
          info: sysInfo,
        );

        await tester.pumpWidget(wrap(topology, mode));
        await tester.pump(const Duration(milliseconds: 500));

        final semantics = tester.getSemantics(
          find.bySemanticsIdentifier('topology-node-master'),
        );
        expect(semantics.identifier, 'topology-node-master');

        handle.dispose();
      });
    });
  }
}

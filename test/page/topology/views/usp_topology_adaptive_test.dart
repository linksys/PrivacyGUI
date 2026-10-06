@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/devices_test_data.dart';
import '../../../mocks/test_data/system_info_test_data.dart';

/// What `LeafVisibility.adaptive` must not cost: a device the E2E suite locates
/// by identifier.
///
/// The full-page topology shows leaves adaptively — drawn while their disc clears
/// 44px, aggregated below that — which is the mode ui_kit's own measurements
/// argue for (9% of taps opened the wrong device at ten leaves per parent, 61% at
/// twelve, with `always`). It has one consequence the other four modes do not:
/// **under adaptive only, devices far outside the visible region are not built at
/// all**, so they are absent from the semantics tree rather than merely small.
///
/// `e2e/tests/P15-topology.spec.ts` D4 finds an offline client by
/// `topology-node-client-<suffix>` and taps it. If adaptive aggregated or culled
/// that node on an ordinary viewport, that spec would fail with a count of zero —
/// and it runs against the real page, not a fixture that pins `always`. So this
/// pins the sparse case: at the density the E2E base actually carries, every
/// client stays individually locatable.
void main() {
  setUpAll(() {
    OuiLookup.initializeForTesting(const {
      '112233': 'Test Vendor',
      'AABBCC': 'Linksys',
    });
  });

  tearDownAll(OuiLookup.reset);

  Widget wrap(GraphData topology, LeafVisibility visibility) => MaterialApp(
        theme: AppTheme.create(brightness: Brightness.light),
        home: Scaffold(
          body: SizedBox(
            // The viewport the E2E suite drives, near enough: wide enough that
            // `auto` resolves to the graph rather than the tree.
            width: 1200,
            height: 900,
            child: AppTopology(
              topology: topology,
              viewMode: TopologyViewMode.graph,
              leafVisibility: visibility,
              nodeRendererRegistry: NodeRendererRegistry.unified,
              enableAnimation: false,
              interactive: false,
            ),
          ),
        ),
      );

  /// Identifiers of every client node present in the semantics tree.
  Set<String> locatableClients(WidgetTester tester, GraphData topology) {
    final wanted = topology.nodes
        .where((n) => n.styleSlot == 'leaf' && n.identifier != null)
        .map((n) => n.identifier!)
        .toSet();
    return wanted
        .where((id) => tester
            .widgetList(
                find.bySemanticsIdentifier(RegExp('^${RegExp.escape(id)}\$')))
            .isNotEmpty)
        .toSet();
  }

  testWidgets('a sparse mesh keeps every client locatable under adaptive',
      (tester) async {
    final handle = tester.ensureSemantics();
    final topology = UspTopologyBuilder.buildFromMeshNetwork(
      meshNetwork: DevicesTestData.createMeshNetwork(),
      info: SystemInfoTestData.create(),
    );
    final clients = topology.nodes.where((n) => n.styleSlot == 'leaf').toList();
    expect(clients, isNotEmpty, reason: 'the fixture must carry clients');

    await tester.pumpWidget(wrap(topology, LeafVisibility.adaptive));
    await tester.pump(const Duration(milliseconds: 500));

    final found = locatableClients(tester, topology);
    expect(
      found.length,
      clients.length,
      reason:
          'every client in a sparse mesh must stay individually locatable — '
          'e2e P15 D4 taps one by identifier, and adaptive is the only mode that '
          'can remove a device from the tree entirely',
    );

    handle.dispose();
  });

  testWidgets('adaptive matches always on a sparse mesh', (tester) async {
    // The comparison that says adaptive costs nothing *here*, rather than
    // asserting a number that would drift with the fixture. Where the two modes
    // agree, switching one for the other is invisible.
    final topology = UspTopologyBuilder.buildFromMeshNetwork(
      meshNetwork: DevicesTestData.createMeshNetwork(),
      info: SystemInfoTestData.create(),
    );

    final counts = <LeafVisibility, int>{};
    for (final mode in [LeafVisibility.always, LeafVisibility.adaptive]) {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(topology, mode));
      await tester.pump(const Duration(milliseconds: 500));
      counts[mode] = locatableClients(tester, topology).length;
      handle.dispose();
    }

    expect(counts[LeafVisibility.adaptive], counts[LeafVisibility.always]);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/devices_test_data.dart';
import '../../../mocks/test_data/system_info_test_data.dart';

/// The one line under a node's name in tree view.
///
/// `GraphNode.extra` is read in exactly two places, which is why it can be given
/// content safely: the tree row's subtitle, and this app's own topology search.
/// The graph view does not draw it at all (the kit's default detail panel would,
/// under an "Info" label, but both call sites pass their own `detailBuilder`).
///
/// It used to be set for two of the three kinds — the master's manufacturer and a
/// leaf's IP — so **every slave row showed a name and nothing else**. That
/// predates the 3.4.0 migration; it surfaced during it because a narrow viewport
/// is where `auto` resolves to the tree, and the tree is the only view that draws
/// this field.
///
/// Two or three facts per row, not everything available: a subtitle competes with
/// the row's own labels and status badge for one line, and the detail panel is
/// where the full set lives.
void main() {
  setUpAll(() {
    OuiLookup.initializeForTesting(const {
      '112233': 'Test Vendor',
      'AABBCC': 'Linksys',
    });
  });

  tearDownAll(OuiLookup.reset);

  final sysInfo = SystemInfoTestData.create();

  GraphNode nodeOf(GraphData topology, String slot) =>
      topology.nodes.firstWhere((n) => n.styleSlot == slot);

  group('every kind of node carries a subtitle', () {
    test('the master shows its model', () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(),
        info: sysInfo,
      );
      final master = nodeOf(topology, 'primary');

      expect(master.extra, isNotNull);
      expect(master.extra, isNotEmpty);
      expect(master.extra, contains(DevicesTestData.defaultModel));
    });

    test('a slave shows its model, and states nothing it cannot word', () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(),
        info: sysInfo,
      );
      final slave = nodeOf(topology, 'secondary');

      // The regression this file exists for: a slave row used to be name-only.
      expect(slave.extra, isNotNull);
      expect(slave.extra, isNotEmpty);
      expect(slave.extra, contains(DevicesTestData.defaultModel));

      // The backhaul medium belongs in this line too, and it is **not** here. It
      // arrives as a firmware string (`MultiAPDevice.Backhaul.LinkType`), so
      // putting it in `extra` printed `Ethernet` on the screen in all 26 locales.
      // Wording it needs a `BuildContext`, which this builder deliberately does
      // not have, so `TopologySubtitle` appends it from the fields recorded in
      // metadata — see `topology_subtitle_test.dart`, which owns that half
      // including the locale assertion.
      expect(slave.extra, isNot(contains('Wi-Fi')));
      expect(slave.extra, isNot(contains('Ethernet')));
      expect(slave.extra, isNot(contains('dBm')));
    });

    test('the fields the medium is worded from are recorded', () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(),
        info: sysInfo,
      );
      final slave = nodeOf(topology, 'secondary');

      // Moving the wording out is only safe while the raw facts still reach the
      // consumer. They were already recorded here for the detail panel; this pins
      // that the subtitle now depends on them too.
      expect(slave.metadata!['backhaulLinkType'], isNotNull);
      expect(slave.metadata!['backhaulSignalStrength'], isNotNull);
    });

    test('a leaf keeps its IP first, and adds the band when there is one', () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createSingleNodeNetwork(
          masterClients: [
            DevicesTestData.createWifiClient(ip: '192.168.1.77'),
          ],
        ),
        info: sysInfo,
      );
      final leaf = nodeOf(topology, 'leaf');

      // The IP is what a viewer scans a device list for, so it leads.
      expect(leaf.extra, startsWith('192.168.1.77'));
    });

    test('a leaf with no IP still shows what it has', () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createSingleNodeNetwork(
          masterClients: [DevicesTestData.createWifiClient(ip: '')],
        ),
        info: sysInfo,
      );
      final leaf = nodeOf(topology, 'leaf');

      // Not a subtitle that starts with a separator, which is what a naive join
      // of an empty first field produces.
      expect(leaf.extra ?? '', isNot(startsWith('·')));
      expect(leaf.extra ?? '', isNot(startsWith(' ')));
    });
  });

  group('the subtitle is what topology search reads', () {
    test('a slave is findable by its model', () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(),
        info: sysInfo,
      );
      final slave = nodeOf(topology, 'secondary');

      // `_matches` in the page reads `extra`, so giving slaves a subtitle also
      // makes them searchable by model — pinned so that a later change to the
      // subtitle's contents is understood to change search too.
      expect(slave.extra!.toLowerCase(),
          contains(DevicesTestData.defaultModel.toLowerCase()));
    });
  });
}

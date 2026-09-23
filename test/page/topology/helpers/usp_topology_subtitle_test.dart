import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/devices_test_data.dart';

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

    test('a Wi-Fi slave shows its model and its backhaul, with the signal', () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(),
        info: sysInfo,
      );
      final slave = nodeOf(topology, 'secondary');

      // The regression this file exists for: a slave row used to be name-only.
      expect(slave.extra, isNotNull);
      expect(slave.extra, isNotEmpty);
      expect(slave.extra, contains(DevicesTestData.defaultModel));
      // The backhaul is the fact that distinguishes one slave from another, so it
      // earns the second slot.
      expect(slave.extra, contains('Wi-Fi'));
      expect(slave.extra, contains('dBm'));
    });

    test('an Ethernet slave names the medium and carries no signal', () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(
          slave: DevicesTestData.createEthernetSlave(),
        ),
        info: sysInfo,
      );
      final slave = nodeOf(topology, 'secondary');

      expect(slave.extra, contains('Ethernet'));
      // A wired backhaul has no RSSI by design, not by absence.
      expect(slave.extra, isNot(contains('dBm')));
    });

    test('a slave whose backhaul firmware did not name shows the model alone',
        () {
      final topology = UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: DevicesTestData.createMeshNetwork(
          slave: DevicesTestData.createWifiSlave(backhaul: BackhaulInfo.none),
        ),
        info: sysInfo,
      );
      final slave = nodeOf(topology, 'secondary');

      // Still not empty — the model is knowable whatever the backhaul says.
      expect(slave.extra, isNotNull);
      expect(slave.extra, contains(DevicesTestData.defaultModel));
      // And no invented medium: `LinkType = None` is the ordinary state on
      // FL-WRT 2.0, and claiming Wi-Fi for it is the defect #1464 closed.
      expect(slave.extra, isNot(contains('Wi-Fi')));
      expect(slave.extra, isNot(contains('Ethernet')));
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

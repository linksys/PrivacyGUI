import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/test_data/devices_test_data.dart';

/// Every node states the appearance it wears, at the point the builder already
/// knows what it is.
///
/// ui_kit 3.4.0 derives structure from the parent edges and will derive a slot
/// too when none is given. The builder does not have to let it: it constructs
/// nodes in three separate loops — `master`, `slaves`, `allClients` — so the
/// answer is known at construction. Stating it there is what keeps the derivation
/// out of the app, which is the whole point of the kit dropping the domain
/// (#1614).
///
/// Two cases show why stating it matters, and they are not symmetrical:
///
/// - **A slave carrying no clients** is a structural leaf *today*, in a graph this
///   build really produces. Derivation gets it wrong now: it would shrink the node
///   to leaf size and let an aggregate fold it away.
/// - **An upstream node above the gateway** would demote the gateway to an
///   interior appearance. Measured: this build emits **no** external node, so the
///   gateway is the structural root and derivation happens to agree. That
///   agreement is a property of today's graph rather than of the rule, so the case
///   is pinned against a constructed graph and labelled as hypothetical.
///
/// Each test asserts the *stated* slot and, where the two differ, what derivation
/// alone would have produced. Without that second half a regression that silently
/// went back to deriving would still pass wherever they agree.
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

  GraphData build(MeshNetwork network) =>
      UspTopologyBuilder.buildFromMeshNetwork(
        meshNetwork: network,
        info: sysInfo,
      );

  group('the slot is stated, not derived', () {
    test('the master wears primary', () {
      final topology = build(DevicesTestData.createMeshNetwork());
      final gateway = topology.nodes.firstWhere((n) => n.id == 'gateway');

      expect(gateway.styleSlot, 'primary');
      expect(resolveSlot(gateway, topology.structureOf(gateway.id)),
          NodeStyleSlot.primary);
    });

    test('every slave wears secondary', () {
      final topology = build(DevicesTestData.createMultiSlaveMeshNetwork());
      final slaves =
          topology.nodes.where((n) => n.id.startsWith('extender-')).toList();

      expect(slaves, isNotEmpty, reason: 'the fixture must carry slaves');
      for (final slave in slaves) {
        expect(slave.styleSlot, 'secondary', reason: slave.id);
        expect(resolveSlot(slave, topology.structureOf(slave.id)),
            NodeStyleSlot.secondary,
            reason: slave.id);
      }
    });

    test('every client wears leaf', () {
      final topology = build(DevicesTestData.createMeshNetwork());
      final clients =
          topology.nodes.where((n) => n.id.startsWith('client-')).toList();

      expect(clients, isNotEmpty, reason: 'the fixture must carry clients');
      for (final client in clients) {
        expect(client.styleSlot, 'leaf', reason: client.id);
        expect(resolveSlot(client, topology.structureOf(client.id)),
            NodeStyleSlot.leaf,
            reason: client.id);
      }
    });
  });

  group('what derivation alone would have got wrong', () {
    test(
        'a slave with no clients is a structural leaf, and is not drawn as one',
        () {
      // Reachable in production: a freshly joined node, or one placed where
      // nothing connects to it. The scene fixtures carry the same shape
      // (`connectedClients: const []`).
      final network = MeshNetwork(
        master: MasterNode(
          deviceId: 'AA:BB:CC:DD:EE:00',
          model: 'MR7500',
          manufacturer: 'Linksys',
          serialNumber: 'SN123456',
          softwareVersion: '1.0.16.26013014',
          dataElementsId: 'AA:BB:CC:DD:EE:00',
          connectedClients: const [],
        ),
        slaves: [
          SlaveNode(
            deviceId: 'AA:BB:CC:DD:EE:01',
            model: 'MX2000',
            manufacturer: 'Linksys',
            serialNumber: 'SN000001',
            softwareVersion: '1.0.16.26013014',
            dataElementsId: 'AA:BB:CC:DD:EE:01',
            connectedClients: const [],
            backhaul: BackhaulInfo(
              parentNodeId: 'AA:BB:CC:DD:EE:00',
              linkType: 'Wi-Fi',
              signalStrength: -55,
            ),
          ),
        ],
      );

      final topology = build(network);
      final slave = topology.nodes
          .firstWhere((n) => n.id == 'extender-AA:BB:CC:DD:EE:01');
      final structure = topology.structureOf(slave.id);

      // Structure genuinely says leaf — the information that it is a node is not
      // in the graph.
      expect(structure.isLeaf, isTrue);
      expect(slotFromStructure(slave, structure), NodeStyleSlot.leaf);

      // The stated slot overrides that, for appearance AND for layout.
      expect(slave.styleSlot, 'secondary');
      expect(resolveSlot(slave, structure), NodeStyleSlot.secondary);
      expect(isTerminalNode(slave, structure), isFalse,
          reason: 'a node must not be folded into an aggregate');
    });

    test(
        'an upstream node would demote the gateway, which stating the slot prevents',
        () {
      // Measured, not assumed: this build emits **no** external node, so the
      // gateway is the structural root and derivation happens to agree with the
      // stated slot. The agreement is a property of today's graph, not of the
      // rule — so the demotion is pinned against a graph that has the upstream
      // node `GraphNode.external` exists for, to show what the stated slot is
      // protecting against.
      final topology = build(DevicesTestData.createMeshNetwork());
      expect(topology.nodes.where((n) => n.isExternal), isEmpty,
          reason: 'if this ever fails, the production graph gained an upstream '
              'node and the gateway arm below stopped being hypothetical');

      final gateway = topology.nodes.firstWhere((n) => n.id == 'gateway');
      final withUpstream = GraphData(
        nodes: [
          GraphNode(id: 'wan', name: 'Internet', external: true),
          gateway.copyWith(parentId: 'wan'),
          ...topology.nodes.where((n) => n.id != 'gateway'),
        ],
        edges: topology.edges,
      );
      final structure = withUpstream.structureOf(gateway.id);

      expect(structure.isRoot, isFalse);
      expect(slotFromStructure(gateway, structure), NodeStyleSlot.secondary,
          reason: 'derivation demotes it — which is why the slot is stated');
      expect(
          resolveSlot(withUpstream.nodes[1], structure), NodeStyleSlot.primary);
    });
  });

  group('the layout anchor', () {
    test('is the gateway', () {
      final topology = build(DevicesTestData.createMeshNetwork());
      expect(topology.anchorNode?.id, 'gateway');
    });

    test('stays the gateway when an upstream node is added above it', () {
      // `anchorNode` is not `rootNode`, and this is the difference: an external
      // node can sit structurally above the gateway without becoming the centre
      // of the picture.
      final topology = build(DevicesTestData.createMeshNetwork());
      final gateway = topology.nodes.firstWhere((n) => n.id == 'gateway');
      final withUpstream = GraphData(
        nodes: [
          GraphNode(id: 'wan', name: 'Internet', external: true),
          gateway.copyWith(parentId: 'wan'),
          ...topology.nodes.where((n) => n.id != 'gateway'),
        ],
        edges: topology.edges,
      );

      expect(withUpstream.rootNode?.id, 'wan');
      expect(withUpstream.anchorNode?.id, 'gateway');
    });
  });
}

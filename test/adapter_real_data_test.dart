import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/topology_adapter.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  test('TopologyAdapter real data reproduction', () {
    // 1. Define Models based on user logs
    final node2F = TopologyModel(
      deviceId: "7c73c181-3761-e5b3-8655-d8ec5e736565",
      location: "二樓",
      isMaster: true,
      isOnline: true,
      isRouter: true,
      model: "MX42",
      isWiredConnection: true,
    );

    final node3F = TopologyModel(
      deviceId: "ab69b7f6-fee4-d83a-5ee1-d8ec5e736510",
      location: "三樓",
      isMaster: false, // assuming child
      isOnline: true,
      isRouter: true,
      model: "MX42",
      isWiredConnection: false,
      signalStrength: -69,
    );

    final nodeMyRouter = TopologyModel(
      deviceId: "0217b8a4-1082-4532-8345-80691abb4694",
      location: "myrouter",
      isMaster: true, // User log says true, confusing but we keep it
      isOnline: false,
      isRouter: true,
      model: "LN16",
      isWiredConnection: false,
    );

    final node3FStudy = TopologyModel(
      deviceId: "4b45e851-0f57-456d-9134-d8ec5e69e72e",
      location: "三樓 書房",
      isMaster: false,
      isOnline: false,
      isRouter: true,
      model: "MX43",
      isWiredConnection: false,
    );

    // 2. Build Tree Structure (Root: 二樓 -> Others)
    final child3F = RouterTopologyNode(data: node3F, children: []);
    final childMyRouter = RouterTopologyNode(data: nodeMyRouter, children: []);
    final child3FStudy = RouterTopologyNode(data: node3FStudy, children: []);

    final root2F = RouterTopologyNode(
      data: node2F,
      children: [child3F, childMyRouter, child3FStudy],
    );

    // 3. Convert
    final meshTopology = TopologyAdapter.convert([root2F]);

    // 4. Inspect Results
    print('Converted ${meshTopology.nodes.length} nodes');
    for (final node in meshTopology.nodes) {
      print('Node: ${node.name} (${node.id})');
      print('  Type: ${node.type}');
      print('  Level: ${node.level}');
      print('  Parent: ${node.parentId}');
      print('  Status: ${node.status}');
    }

    // 5. Assertions
    expect(meshTopology.nodes.length, 4, reason: 'Should have 4 nodes');

    final rootNode =
        meshTopology.nodes.firstWhere((n) => n.id == node2F.deviceId);
    expect(rootNode.level, 0, reason: 'Root should be level 0');
    expect(
        rootNode.type == MeshNodeType.gateway ||
            rootNode.type == MeshNodeType.extender,
        true);

    final myRouterNode =
        meshTopology.nodes.firstWhere((n) => n.id == nodeMyRouter.deviceId);
    expect(myRouterNode.level, 1, reason: 'Child should be level 1');
    expect(myRouterNode.parentId, node2F.deviceId);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_menu.dart';
import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Where the topology offers "Add nodes" (#879): on the controller, and only
/// when the router and the mode offer the flow.
void main() {
  GraphNode node(String? slot) =>
      GraphNode(id: 'n', name: 'n', styleSlot: slot);

  List<AppPopupMenuItem<String>>? menuOn(String? slot, {bool can = true}) =>
      topologyNodeMenu(node(slot),
          canAddNodes: can, addNodesLabel: 'Add nodes');

  group('topologyNodeMenu - where', () {
    test('the controller offers Add nodes', () {
      final menu = menuOn(TopologySlots.master);

      expect(menu, hasLength(1));
      expect(menu!.single.value, kTopologyMenuAddNodes);
      expect(menu.single.label, 'Add nodes');
      expect(menu.single.identifier, kTopologyNodeAddNodesIdentifier);
    });

    test('an agent offers nothing', () {
      // Onboarding runs from the controller's own Bluetooth, and an agent
      // refuses the request.
      expect(menuOn(TopologySlots.slave), isNull);
    });

    test('a device offers nothing', () {
      expect(menuOn(TopologySlots.device), isNull);
    });

    test('a node with no slot this app assigns offers nothing', () {
      expect(menuOn(null), isNull);
      expect(menuOn('tertiary'), isNull);
    });
  });

  group('topologyNodeMenu - whether', () {
    test('nothing, even on the controller, when the flow is not offered', () {
      // No onboarding API on this firmware, or Remote Assistance.
      expect(menuOn(TopologySlots.master, can: false), isNull);
    });
  });

  group('topologyNodeMenu - the E2E hook', () {
    test('carries the prefix the E2E generator harvests', () {
      expect(kTopologyNodeAddNodesIdentifier, startsWith('topology-node-'));
    });
  });
}

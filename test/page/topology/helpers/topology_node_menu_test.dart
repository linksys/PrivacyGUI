import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_menu.dart';
import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Where the topology offers "Add nodes" (#879): on the controller, and only
/// when the router and the mode offer the flow.
void main() {
  GraphNode node(String? slot) =>
      GraphNode(id: 'n', name: 'n', styleSlot: slot);

  List<AppPopupMenuItem<String>>? menuOn(
    String? slot, {
    bool can = true,
    Set<NodeAction> actions = const {},
  }) =>
      topologyNodeMenu(
        node(slot),
        canAddNodes: can,
        addNodesLabel: 'Add nodes',
        nodeActions: actions,
        rebootLabel: 'Reboot',
        factoryResetLabel: 'Factory Reset',
      );

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

  // #876. What each node offers is the caller's (`nodeActionsOf`): the
  // router both, an agent what its X_LINKSYS_SupportedOperations lists.
  group('topologyNodeMenu - node actions (#876)', () {
    const both = {NodeAction.reboot, NodeAction.factoryReset};

    test('the controller lists Add nodes, then Reboot, then Factory Reset', () {
      final menu = menuOn(TopologySlots.master, actions: both);

      expect(menu!.map((i) => i.value), [
        kTopologyMenuAddNodes,
        kTopologyMenuReboot,
        kTopologyMenuFactoryReset,
      ]);
      expect(
          menu.map((i) => i.label), ['Add nodes', 'Reboot', 'Factory Reset']);
    });

    test('the controller keeps its node actions when Add nodes is not offered',
        () {
      final menu = menuOn(TopologySlots.master, can: false, actions: both);

      expect(menu!.map((i) => i.value),
          [kTopologyMenuReboot, kTopologyMenuFactoryReset]);
    });

    test('an agent offers exactly the actions it lists', () {
      expect(
        menuOn(TopologySlots.slave, actions: {NodeAction.reboot})!
            .map((i) => i.value),
        [kTopologyMenuReboot],
      );
    });

    test('an agent that lists nothing has no menu', () {
      expect(menuOn(TopologySlots.slave), isNull);
    });

    test('a device has no menu whatever it is given', () {
      expect(menuOn(TopologySlots.device, actions: both), isNull);
    });

    test('the menu value names the action it runs', () {
      expect(topologyMenuNodeAction(kTopologyMenuReboot), NodeAction.reboot);
      expect(topologyMenuNodeAction(kTopologyMenuFactoryReset),
          NodeAction.factoryReset);
      expect(topologyMenuNodeAction(kTopologyMenuAddNodes), isNull);
    });
  });

  group('topologyNodeMenu - the E2E hook', () {
    test('carries the prefix the E2E generator harvests', () {
      expect(kTopologyNodeAddNodesIdentifier, startsWith('topology-node-'));
      expect(kTopologyNodeRebootIdentifier, startsWith('topology-node-'));
      expect(kTopologyNodeFactoryResetIdentifier, startsWith('topology-node-'));
    });

    test('each node action item carries its own hook', () {
      final menu = menuOn(TopologySlots.slave,
          actions: {NodeAction.reboot, NodeAction.factoryReset});

      expect(menu!.map((i) => i.identifier), [
        kTopologyNodeRebootIdentifier,
        kTopologyNodeFactoryResetIdentifier,
      ]);
    });
  });
}

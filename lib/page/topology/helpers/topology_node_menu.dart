import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The menu value of the "Add nodes" item.
const String kTopologyMenuAddNodes = 'addNodes';

/// E2E hook for the "Add nodes" menu item. Singleton: it is offered on the
/// controller only, and a topology has one.
///
/// Prefixed `topology-node-` so the E2E generator, which harvests indirect hooks
/// under that prefix, picks it up from this constant.
const String kTopologyNodeAddNodesIdentifier = 'topology-node-add-nodes';

/// The menu values of the node actions (#876).
const String kTopologyMenuReboot = 'reboot';
const String kTopologyMenuFactoryReset = 'factoryReset';

/// E2E hooks for the node action items. Not keyed per node: the kit shows one
/// node's menu at a time, once its button is pressed, so within an open menu
/// each hook is unique; a spec opens the node's menu by the node's own hook
/// first. Prefixed `topology-node-` like [kTopologyNodeAddNodesIdentifier].
const String kTopologyNodeRebootIdentifier = 'topology-node-reboot';
const String kTopologyNodeFactoryResetIdentifier =
    'topology-node-factory-reset';

/// The [NodeAction] a node menu [value] runs, or null for any other item.
NodeAction? topologyMenuNodeAction(String value) => switch (value) {
      kTopologyMenuReboot => NodeAction.reboot,
      kTopologyMenuFactoryReset => NodeAction.factoryReset,
      _ => null,
    };

/// The per-node menu the topology offers on [node], or null for none.
///
/// **Add nodes** ([addNodesLabel]) on the **controller only**: onboarding runs
/// from the controller's own Bluetooth, so the new node has to be near the
/// controller and not near whichever node the menu was opened on — and on an
/// agent the router refuses the request. The controller is the node in the
/// master slot, which `MeshTopologyBuilder` decides by `Network.ControllerID`
/// through `isMeshController`, the rule every other controller check uses.
///
/// [canAddNodes] is whether this router and this mode offer the flow at all — the
/// `bleOnboarding` capability and the surface's `addNodesEntry`. Both are the
/// caller's to read; this decides only where the item goes.
///
/// **Reboot** and **Factory Reset** (#876) on any mesh node, for the actions in
/// [nodeActions]: the caller's `nodeActionsOf` — both on the router, which
/// runs the Administration page's flow, and on an agent what its
/// `X_LINKSYS_SupportedOperations` lists. After Add nodes, the most
/// destructive last. A device or the external node gets no menu.
List<AppPopupMenuItem<String>>? topologyNodeMenu(
  GraphNode node, {
  required bool canAddNodes,
  required String addNodesLabel,
  required Set<NodeAction> nodeActions,
  required String rebootLabel,
  required String factoryResetLabel,
}) {
  if (!TopologySlots.isMeshNode(node)) return null;
  final items = [
    if (canAddNodes && TopologySlots.of(node) == NodeStyleSlot.primary)
      AppPopupMenuItem(
        value: kTopologyMenuAddNodes,
        label: addNodesLabel,
        icon: Icons.add_circle_outline,
        identifier: kTopologyNodeAddNodesIdentifier,
      ),
    if (nodeActions.contains(NodeAction.reboot))
      AppPopupMenuItem(
        value: kTopologyMenuReboot,
        label: rebootLabel,
        icon: Icons.restart_alt,
        identifier: kTopologyNodeRebootIdentifier,
      ),
    if (nodeActions.contains(NodeAction.factoryReset))
      AppPopupMenuItem(
        value: kTopologyMenuFactoryReset,
        label: factoryResetLabel,
        icon: Icons.settings_backup_restore,
        identifier: kTopologyNodeFactoryResetIdentifier,
      ),
  ];
  return items.isEmpty ? null : items;
}

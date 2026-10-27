import 'package:flutter/material.dart';
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

/// The per-node menu the topology offers on [node], or null for none.
///
/// One item today, "Add nodes" ([addNodesLabel]), on the **controller only**:
/// onboarding runs from the controller's own Bluetooth, so the new node has to be
/// near the controller and not near whichever node the menu was opened on — and
/// on an agent the router refuses the request. The controller is the node in the
/// master slot, which `MeshTopologyBuilder` decides by `Network.ControllerID`
/// through `isMeshController`, the rule every other controller check uses.
///
/// [canAddNodes] is whether this router and this mode offer the flow at all — the
/// `bleOnboarding` capability and the surface's `addNodesEntry`. Both are the
/// caller's to read; this decides only where the item goes.
List<AppPopupMenuItem<String>>? topologyNodeMenu(
  GraphNode node, {
  required bool canAddNodes,
  required String addNodesLabel,
}) {
  if (!canAddNodes) return null;
  if (TopologySlots.of(node) != NodeStyleSlot.primary) return null;
  return [
    AppPopupMenuItem(
      value: kTopologyMenuAddNodes,
      label: addNodesLabel,
      icon: Icons.add_circle_outline,
      identifier: kTopologyNodeAddNodesIdentifier,
    ),
  ];
}

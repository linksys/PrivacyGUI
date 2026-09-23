import 'package:flutter/foundation.dart';
import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A resolved navigation target for a tapped topology node: the named route
/// plus its query parameters.
@immutable
class TopologyNavTarget {
  const TopologyNavTarget(this.route, this.queryParameters);

  final String route;
  final Map<String, String> queryParameters;
}

/// Pure mapping from a tapped [GraphNode] to its navigation target, or `null`
/// when the node is not navigable.
///
/// Lives here rather than beside a view because two of them ask: the full-page
/// view routes a tree row's tap, and the detail panel's own Details button routes
/// from wherever the panel was opened. One copy is what keeps the two
/// destinations — and the offline gate below — from drifting apart.
///
/// The two node families are deliberately treated differently:
///
/// - **Clients** are navigable regardless of status. An offline client opens
///   its Device Detail page just like it does from the device list and from a
///   node's "Connected devices" list; the destination already renders the
///   correct online/offline state, so there is nothing to gate against.
/// - **Master / slave nodes** keep an offline gate. Their Node Detail page still
///   hardcodes an active status badge, so opening it for a powered-off node
///   would show a wrong (green) status. That is tracked by #1465; until it is
///   fixed, the node arm stays gated. Do NOT "tidy" the leaf arm to match
///   the node arm — the difference is intentional.
TopologyNavTarget? topologyNavTargetFor(
  GraphNode node, {
  Map<String, dynamic>? metadata,
}) {
  // The external node is drawn beside the hierarchy and has no page.
  if (node.isExternal) return null;

  // Which metadata to resolve the destination from.
  //
  // Normally the node's own, which is what both topology views hand the kit. But
  // `NodeDetailPopup.builder` takes `metadata` as a parameter *beside* the node —
  // the signature `NodeDetailBuilder` requires — and its own rows read that
  // parameter. Resolving the destination from `node.metadata` while the rows read
  // the argument gave one widget two sources for one fact, and the two disagree
  // wherever a caller passes metadata the node does not carry.
  final fields = metadata ?? node.metadata;

  if (TopologySlots.isMeshNode(node)) {
    // Offline gate for mesh nodes only — see #1465 (doc above).
    if (node.status == NodeState.inactive) return null;
    final deviceId = fields?['deviceId'] as String?;
    if (deviceId == null || deviceId.isEmpty) return null;
    return TopologyNavTarget(
      RouteNamed.uspNodeDetail,
      {'deviceId': deviceId},
    );
  }

  if (TopologySlots.isDevice(node)) {
    final mac = fields?['mac'] as String?;
    if (mac == null || mac.isEmpty) return null;
    return TopologyNavTarget(
      RouteNamed.uspDeviceDetail,
      {'mac': mac},
    );
  }

  // A slot this app does not assign — not reachable from `UspTopologyBuilder`,
  // which states one of the three on every node, so there is no destination to
  // guess at.
  return null;
}

/// Sort rank for [node]: master, then slave, then device, then external.
///
/// Reads the slot the builder **stated**, which is this app's own classification.
/// Deriving from structure instead would rank a slave carrying no clients as a
/// device, which is measured and reachable today; and it would demote the gateway
/// the moment an upstream external node is added above it. See
/// `usp_topology_slot_origin_test.dart`, which pins both (#1614).
int topologyRolePriority(GraphNode node) {
  if (node.isExternal) return 3;
  return switch (TopologySlots.of(node)) {
    NodeStyleSlot.primary => 0,
    NodeStyleSlot.secondary => 1,
    // A device, and — deliberately — a node whose slot this app did not assign.
    // It sorts last among the non-external nodes rather than being promoted above
    // the ones we did classify. `topologyNavTargetFor` gives the same input no
    // page; the two answers differ because the questions do, and both now read
    // the unknown case from one place.
    NodeStyleSlot.leaf => 2,
    NodeStyleSlot.tertiary => 2,
    null => 2,
  };
}

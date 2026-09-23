import 'package:flutter/foundation.dart';
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
TopologyNavTarget? topologyNavTargetFor(GraphNode node) {
  // The external node is drawn beside the hierarchy and has no page.
  if (node.isExternal) return null;

  switch (node.styleSlot) {
    case 'primary':
    case 'secondary':
      // Offline gate for mesh nodes only — see #1465 (doc above).
      if (node.status == NodeState.inactive) return null;
      final deviceId = node.metadata?['deviceId'] as String?;
      if (deviceId == null || deviceId.isEmpty) return null;
      return TopologyNavTarget(
        RouteNamed.uspNodeDetail,
        {'deviceId': deviceId},
      );
    case 'leaf':
      final mac = node.metadata?['mac'] as String?;
      if (mac == null || mac.isEmpty) return null;
      return TopologyNavTarget(
        RouteNamed.uspDeviceDetail,
        {'mac': mac},
      );
    default:
      // A slot this app does not assign. Not reachable from
      // `UspTopologyBuilder`, which states one of the three above on every node,
      // so there is no destination to guess at.
      return null;
  }
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
  return switch (node.styleSlot) {
    'primary' => 0,
    'secondary' => 1,
    'leaf' => 2,
    _ => 2,
  };
}

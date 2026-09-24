import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A resolved navigation target for a tapped topology node: the named route
/// plus its query parameters.
///
/// `Equatable` for the reason the tests need rather than the one Article XI names:
/// that article governs UI models and provider state, and this is neither — it is a
/// function's return value, gone by the next frame. But `==` on identity meant every
/// assertion about a destination had to be written as two field comparisons, which
/// is how a test ends up checking the route and forgetting the parameters.
///
/// [queryParameters] is handed to the constructor and exposed directly, so a caller
/// that mutates the map it passed in mutates this. Every caller passes a literal;
/// the field stays a plain `Map` because `go_router` wants one, and wrapping it
/// would trade a real dependency for a theoretical one.
@immutable
class TopologyNavTarget extends Equatable {
  const TopologyNavTarget(this.route, this.queryParameters);

  final String route;
  final Map<String, String> queryParameters;

  @override
  List<Object?> get props => [route, queryParameters];
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

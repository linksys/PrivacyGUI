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
/// [queryParameters] is copied, not aliased. This class is `@immutable` and its
/// `hashCode` derives from that map, so a caller mutating what it passed in would
/// change this object's identity after construction. Every caller passes a literal
/// today, which makes the defect theoretical — an argument for closing it cheaply
/// rather than describing it, which is what an earlier version of this comment did.
/// `Map.unmodifiable` also makes the promise enforced: a later caller that tries to
/// write through the getter fails loudly instead of silently succeeding.
///
/// The constructor is no longer `const`. No call site wanted it — every target is
/// built from runtime values.
@immutable
class TopologyNavTarget extends Equatable {
  TopologyNavTarget(this.route, Map<String, String> queryParameters)
      : queryParameters = Map.unmodifiable(queryParameters);

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
/// destinations from drifting apart.
///
/// **No node is gated on liveness.** An offline client opens its Device Detail
/// page, as it does from the device list. An offline extender opens its Node
/// Detail page (#1443), which renders `node.isOnline` (#1465) and says how long
/// the node has been offline. Both destinations render the right state, so
/// there is nothing to gate against. A node is unreachable only when it has no
/// identifier to route by.
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

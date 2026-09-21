import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';

/// How a slave's backhaul parent resolved.
///
/// Five outcomes, because `deviceIdToExtenderId[parent] ?? gatewayId` collapsed
/// three of them into one answer: a node firmware named no parent for, a node
/// correctly parented by the gateway, and a node whose named parent is absent
/// from the tree all came out as "attached to the gateway". The first two are
/// ordinary and the third is a lost hop, and a support bundle could not tell
/// them apart (#1441, AC2).
enum BackhaulParentOutcome {
  /// Firmware reported no `BackhaulDeviceID` at all.
  ///
  /// Not a failure: it is the controller's shape, and an agent whose parent
  /// field has not been populated yet. Attaches to the gateway because that is
  /// the only place a parentless node can go.
  noneReported,

  /// The named parent is the gateway.
  ///
  /// The outcome that used to be indistinguishable from [miss]. The gateway's
  /// own MAC is deliberately not a key in the extender lookup — it has no
  /// `extender-` id — so recognising it needs the gateway's identifiers passed
  /// in beside that map.
  gateway,

  /// The named parent is another node in the tree.
  extender,

  /// The named parent is not in the tree.
  ///
  /// A lost hop: the node is attached to the gateway, so a chain silently
  /// renders as a star. Causes seen or plausible: a slave present in
  /// DataElements but not in `Hosts` (so it is not in `meshNetwork.slaves` at
  /// all), a parent that dropped out between the two reads, and an identifier
  /// written in a form the lookup does not key on.
  miss,

  /// The named parent resolved, but the edge closed a cycle and was dropped.
  ///
  /// The node is attached to the gateway instead. See [resolveBackhaulParents]
  /// for why a cycle may not be emitted and how the victim is chosen.
  cycleBroken,
}

/// One slave's resolved parent, and how it was resolved.
class BackhaulParent {
  /// The slave's node id in the emitted graph (`extender-<deviceId>`).
  final String extenderId;

  /// `MultiAPDevice.Backhaul.BackhaulDeviceID` exactly as firmware reported it.
  ///
  /// Kept unnormalised on purpose: this is what a log line has to carry for
  /// anyone comparing it against a router capture.
  final String? reportedParentDeviceId;

  /// The parent this node is emitted with — a sibling's [extenderId], or the
  /// gateway's node id.
  final String parentId;

  final BackhaulParentOutcome outcome;

  /// The members of the cycle this node's edge closed, in input order.
  ///
  /// Empty for every outcome but [BackhaulParentOutcome.cycleBroken], and
  /// carried only by the one node whose edge was dropped, so a caller logging
  /// [BackhaulParentGraph.brokenCycles] reports each cycle once rather than once
  /// per member.
  final List<String> cycle;

  const BackhaulParent({
    required this.extenderId,
    required this.reportedParentDeviceId,
    required this.parentId,
    required this.outcome,
    this.cycle = const [],
  });

  @override
  String toString() => '$extenderId → $parentId (${outcome.name}'
      '${reportedParentDeviceId == null ? '' : ', reported '
          '$reportedParentDeviceId'}'
      '${cycle.isEmpty ? '' : ', cycle ${cycle.join(' → ')}'})';
}

/// Every slave's resolved parent, as an acyclic graph.
class BackhaulParentGraph {
  /// One entry per slave, in the order the slaves were given.
  final List<BackhaulParent> parents;

  const BackhaulParentGraph(this.parents);

  /// The parent lookup the builder emits from.
  Map<String, String> get parentIdByExtenderId =>
      {for (final p in parents) p.extenderId: p.parentId};

  /// Slaves whose named parent was not found — one log line each.
  Iterable<BackhaulParent> get misses =>
      parents.where((p) => p.outcome == BackhaulParentOutcome.miss);

  /// One entry per cycle broken, not per node involved in one.
  Iterable<BackhaulParent> get brokenCycles =>
      parents.where((p) => p.outcome == BackhaulParentOutcome.cycleBroken);
}

/// Resolves each slave's parent into an **acyclic** graph, and says how.
///
/// [slaves] are in emission order; [extenderIdByNodeMac] maps every identifier a
/// slave is known by (its `Hosts` MAC and its DataElements MAC, which differ) to
/// that slave's `extenderId`; [gatewayNodeMacs] are the master's identifiers,
/// which have no `extender-` id of their own and so cannot be in that map.
/// All three sets of keys must be [normalizeMac]d — the map's keys and the value
/// probed against them normalised two different ways is itself a cause of
/// [BackhaulParentOutcome.miss], which is why there is one function for it and
/// not a hand-written `toUpperCase().replaceAll(...)` per site.
///
/// ## Why a cycle may not be emitted
///
/// Nothing here walks the graph — each parent is one map lookup — so this code
/// cannot loop and never could. The walk is **ui_kit's**:
/// `concentric_layout.dart`'s `_positionChildrenRecursively` and
/// `topology_tree_view.dart`'s `buildSubtree` both recurse over the `parentId`
/// relation we hand them, and neither carries a visited set or a depth cap
/// (checked in v3.3.2). A cycle therefore overflows the stack inside a widget we
/// may not hand-roll around (constitution Article XV), which leaves exactly one
/// defence: do not emit one.
///
/// ## How the cycle is broken
///
/// The **earliest member in [slaves] order** is re-parented to the gateway.
/// Stated as a rule rather than taken as whatever the walk happened to find
/// first, because those differ: the same cycle discovered from a different
/// starting node breaks at a different edge, so "the node where the walk
/// re-entered its path" would make the rendered tree depend on node ordering
/// twice over. Membership of a cycle does not depend on where the walk started;
/// position in the input does not depend on the walk at all.
///
/// One pass suffices: every node has exactly one parent, so the graph is
/// functional and its cycles are disjoint — breaking one cannot create or hide
/// another.
BackhaulParentGraph resolveBackhaulParents({
  required List<({String extenderId, String? parentDeviceId})> slaves,
  required Map<String, String> extenderIdByNodeMac,
  required Set<String> gatewayNodeMacs,
  required String gatewayId,
}) {
  final resolved = <String, BackhaulParent>{};

  for (final slave in slaves) {
    final reported = slave.parentDeviceId;
    final normalized = reported == null ? '' : normalizeMac(reported);

    final BackhaulParentOutcome outcome;
    final String parentId;
    if (normalized.isEmpty) {
      outcome = BackhaulParentOutcome.noneReported;
      parentId = gatewayId;
    } else if (gatewayNodeMacs.contains(normalized)) {
      outcome = BackhaulParentOutcome.gateway;
      parentId = gatewayId;
    } else {
      final extenderId = extenderIdByNodeMac[normalized];
      if (extenderId == null) {
        outcome = BackhaulParentOutcome.miss;
        parentId = gatewayId;
      } else {
        outcome = BackhaulParentOutcome.extender;
        parentId = extenderId;
      }
    }

    resolved[slave.extenderId] = BackhaulParent(
      extenderId: slave.extenderId,
      reportedParentDeviceId: reported,
      parentId: parentId,
      outcome: outcome,
    );
  }

  final order = slaves.map((s) => s.extenderId).toList();

  for (final start in order) {
    final path = <String>[];
    var current = start;
    while (true) {
      if (path.contains(current)) {
        // The cycle is the path from this node's first appearance onward;
        // anything before it merely points into the cycle.
        final cycle = path.sublist(path.indexOf(current));
        final victim = order.firstWhere(cycle.contains);
        final was = resolved[victim]!;
        resolved[victim] = BackhaulParent(
          extenderId: was.extenderId,
          reportedParentDeviceId: was.reportedParentDeviceId,
          parentId: gatewayId,
          outcome: BackhaulParentOutcome.cycleBroken,
          cycle: cycle,
        );
        break;
      }
      path.add(current);
      final parent = resolved[current]?.parentId;
      if (parent == null || parent == gatewayId) break;
      current = parent;
    }
  }

  return BackhaulParentGraph(
    [for (final id in order) resolved[id]!],
  );
}

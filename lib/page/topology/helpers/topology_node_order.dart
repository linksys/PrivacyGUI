import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';

/// The order this app puts topology siblings in.
///
/// Read by the tree view only — `nodeComparator` is consumed in
/// `topology_tree_view.dart` and nowhere else, so the three call sites that pin
/// `viewMode: graph` (the dashboard card, the AI section, the theme studio tab)
/// would get no effect from passing one. That is why only the full page does.
///
/// Lives here rather than as a private static on the page's `State` because it is
/// a rule about what the viewer sees, and a rule on a `State` can only be tested
/// by pumping the whole page and reading rows off the screen.
class TopologyNodeOrder {
  TopologyNodeOrder._();

  /// Active before inactive, then by role, then by name.
  ///
  /// Status leads because an unreachable device is the one a viewer is looking
  /// for; name breaks the remaining ties so that two runs over unchanged data
  /// draw the same order, which `Set`-ordered or map-ordered input does not give.
  static int compare(GraphNode a, GraphNode b) {
    if (a.isInactive && !b.isInactive) return 1;
    if (!a.isInactive && b.isInactive) return -1;

    final byRole = priorityOf(a) - priorityOf(b);
    if (byRole != 0) return byRole;

    return a.name.compareTo(b.name);
  }

  /// Sort rank for [node]: master, then slave, then device, then external.
  ///
  /// Reads the slot the builder **stated**, which is this app's own
  /// classification. Deriving from structure instead would rank a slave carrying
  /// no clients as a device, which is measured and reachable today; and it would
  /// demote the gateway the moment an upstream external node is added above it.
  /// See `usp_topology_slot_origin_test.dart`, which pins both (#1614).
  static int priorityOf(GraphNode node) {
    if (node.isExternal) return 3;
    return switch (TopologySlots.of(node)) {
      NodeStyleSlot.primary => 0,
      NodeStyleSlot.secondary => 1,
      // A device, and — deliberately — a node whose slot this app did not
      // assign. It sorts last among the non-external nodes rather than being
      // promoted above the ones we did classify. `topologyNavTargetFor` gives the
      // same input no page; the two answers differ because the questions do, and
      // both read the unknown case from one place.
      NodeStyleSlot.leaf => 2,
      NodeStyleSlot.tertiary => 2,
      null => 2,
    };
  }
}

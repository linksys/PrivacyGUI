import 'package:ui_kit_library/ui_kit.dart';

/// Which ui_kit appearance each kind of node in this app's mesh wears.
///
/// ui_kit 3.4.0 takes the slot as a `String?`, deliberately: one field names both
/// a built-in [NodeStyleSlot] and a key into a consumer's own `extraNodeStyles`.
/// That is the right shape for the library and the wrong shape to scatter through
/// a consumer — the vocabulary was spelled as a literal at 13 write sites and
/// three read sites, where a typo costs a node its place on screen and no compiler
/// notices.
///
/// So the app names it once here: the three constants are what the builder writes,
/// and [of] is what every reader asks — which is also what makes the "a slot we did
/// not assign" case answerable in one place instead of two.
class TopologySlots {
  TopologySlots._();

  /// The master — the node the picture is arranged around.
  static const master = 'primary';

  /// A slave, whether or not it currently carries any devices.
  static const slave = 'secondary';

  /// A terminal device.
  static const device = 'leaf';

  /// The slot [node] was built with, as the kit's enum, or null for one this app
  /// does not assign.
  ///
  /// Delegates to the kit's own `parseNodeStyleSlot`, which already has exactly
  /// this contract — null when the string names no built-in slot, because the
  /// caller's fallback is to derive from structure rather than to guess. Writing a
  /// second copy here would be a second place for the two to drift.
  ///
  /// Null therefore covers two cases a reader must not confuse with a device: a
  /// slot spelled wrong, and a name the kit authors but this app never assigns
  /// (`tertiary`, or a consumer key in `extraNodeStyles`).
  static NodeStyleSlot? of(GraphNode node) =>
      parseNodeStyleSlot(node.styleSlot);

  /// Whether [node] is one of this app's mesh nodes — a master or a slave.
  static bool isMeshNode(GraphNode node) {
    final slot = of(node);
    return slot == NodeStyleSlot.primary || slot == NodeStyleSlot.secondary;
  }

  /// Whether [node] is a terminal device.
  ///
  /// **An unassigned slot is not a device.** That is the decision this exists to
  /// hold in one place: two readers of the same node used to answer it differently
  /// — navigation treated an unknown slot as having no page, while the sort ranked
  /// it alongside devices. Neither was wrong on its own; disagreeing was.
  static bool isDevice(GraphNode node) => of(node) == NodeStyleSlot.leaf;
}

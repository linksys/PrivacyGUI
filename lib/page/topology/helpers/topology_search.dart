import 'package:ui_kit_library/ui_kit.dart';

/// Which nodes a viewer's query matches.
///
/// Pure, and separate from the view for the same reason the navigation target is:
/// it is a decision about this app's data rather than about a widget, and a
/// private method on a `State` cannot be tested at all.
///
/// The fields searched are the ones a viewer knows a device by — the same set the
/// device list offers under `searchByNameMacIp` — plus the subtitle, which carries
/// a leaf's IP and a node's model.
class TopologySearch {
  TopologySearch._();

  /// The ids of every node in [topology] matching [query].
  ///
  /// An empty or whitespace-only query matches nothing, rather than everything:
  /// the caller's contract is "these are the matches to emphasise", and
  /// emphasising all of them is the same as emphasising none while costing a
  /// relayout.
  static Set<String> match(GraphData topology, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const {};
    return topology.nodes
        .where((node) => matchesNode(node, needle))
        .map((node) => node.id)
        .toSet();
  }

  /// Whether one node matches an already-normalised [needle].
  ///
  /// [needle] must be trimmed and lower-cased — [match] is what does that, and
  /// this is exposed beside it so a caller filtering its own list does not have to
  /// re-derive the field set.
  static bool matchesNode(GraphNode node, String needle) {
    if (node.name.toLowerCase().contains(needle)) return true;
    // The subtitle: a leaf's IP and band, a node's model and backhaul.
    if ((node.extra ?? '').toLowerCase().contains(needle)) return true;
    final metadata = node.metadata;
    if (metadata == null) return false;
    // A device is as often known by its address as by its name, and the two kinds
    // of node keep theirs under different keys.
    for (final key in const ['mac', 'deviceId']) {
      final value = metadata[key];
      if (value is String && value.toLowerCase().contains(needle)) return true;
    }
    return false;
  }
}

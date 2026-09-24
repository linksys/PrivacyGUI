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
  /// Takes the query **raw** — trimming and case-folding happen here, so a caller
  /// passes what the viewer typed and nothing else. That split is the point: a
  /// caller that normalises first would be doing the work twice and would have to
  /// keep its own idea of "normalised" in step with this one.
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

  /// The match a viewer should be taken to, or null when [query] matches nothing.
  ///
  /// Stated as its own function because "which match" is a decision, and reading
  /// `.first` off the set [match] returns would make it an accident: that is
  /// `LinkedHashSet` insertion order, which is the order `GraphData.nodes`
  /// happens to be in, which is the order the builder happens to emit. None of
  /// those are promises.
  ///
  /// The promise made instead: **the match closest to the anchor**, breaking ties
  /// by name. A viewer who types a partial name and gets moved somewhere expects
  /// the nearest thing it could have meant, not whichever row the data started
  /// with.
  static String? focusTarget(GraphData topology, String query) {
    final matched = match(topology, query);
    if (matched.isEmpty) return null;

    final structure = topology.structure;
    final nodes = topology.nodes.where((n) => matched.contains(n.id)).toList()
      ..sort((a, b) {
        final byDepth = structure[a.id].depth.compareTo(structure[b.id].depth);
        if (byDepth != 0) return byDepth;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return nodes.first.id;
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

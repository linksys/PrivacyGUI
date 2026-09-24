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
  /// Its own function because "which match" is a decision. `.first` off the set
  /// [match] returns would make it an accident — that is insertion order, which is
  /// the order the builder happens to emit.
  ///
  /// The promise made instead: **the shallowest match**, breaking ties by name.
  ///
  /// Shallowest, stated as such: an earlier wording here said "closest to the
  /// anchor", which is a different rule and not the one implemented — nothing
  /// consults `GraphData.anchorNode`. On this app's graphs the two coincide, because
  /// the anchor *is* the depth-0 gateway, but a graph with several roots would
  /// separate them and the code would follow depth.
  static String? focusTarget(GraphData topology, String query) =>
      targetAmong(topology, match(topology, query));

  /// The same decision, over matches the caller already has.
  ///
  /// The view computes the set to highlight and then needs one of them to move to.
  /// Going back through [focusTarget] scanned every node a second time per
  /// keystroke — and worse, it was a *second evaluation*: the graph comes from a
  /// provider, so the two passes could disagree and the view could highlight one
  /// set while focusing a node outside it.
  ///
  /// Kept as a fold rather than a sort: only the best candidate is wanted, and a
  /// comparator over a list is both more work and more surface.
  static String? targetAmong(GraphData topology, Set<String> matched) {
    if (matched.isEmpty) return null;

    final structure = topology.structure;
    GraphNode? best;
    int? bestDepth;

    for (final node in topology.nodes) {
      if (!matched.contains(node.id)) continue;

      // `structure[]` never returns null — the kit answers an unknown id with
      // `NodeStructure.unknown` (`depth: 0`) rather than throwing, because its own
      // callers are layout and paint. So an orphan sorts as if it were a root,
      // which is a real ordering and not an error to guard.
      final depth = structure[node.id].depth;
      if (best == null ||
          depth < bestDepth! ||
          (depth == bestDepth &&
              node.name.toLowerCase().compareTo(best.name.toLowerCase()) < 0)) {
        best = node;
        bestDepth = depth;
      }
    }

    return best?.id;
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

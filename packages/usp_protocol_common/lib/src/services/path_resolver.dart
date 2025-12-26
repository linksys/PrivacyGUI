import '../interfaces/i_traversable_node.dart';
import '../value_objects/usp_path.dart';

/// A utility class for resolving USP paths in a tree-like data structure.
class PathResolver {
  /// Resolves a [UspPath] in a data structure that implements [ITraversableNode].
  ///
  /// [root] is the starting point of the traversal.
  /// [path] is the target path.
  List<T> resolve<T extends ITraversableNode<T>>(T root, UspPath path) {
    final segments = path.segments;
    final results = <T>[];

    // Recursive traversal function
    void traverse(T node, List<String> currentSegments) {
      // Base Case: Path traversal complete, target found
      if (currentSegments.isEmpty) {
        results.add(node);
        return;
      }

      final currentSegment = currentSegments.first;
      final remainingSegments = currentSegments.sublist(1);

      // --- Case A: Wildcard (*) ---
      if (currentSegment == '*') {
        // Use the interface method getAllChildren()
        for (final child in node.getAllChildren()) {
          traverse(child, remainingSegments);
        }
      }
      // --- Case B: Exact Match ---
      else {
        // Use the interface method getChild()
        final child = node.getChild(currentSegment);
        if (child != null) {
          traverse(child, remainingSegments);
        }
      }
    }

    // Startup logic: Handle the Root Name (e.g., "Device")
    // If the path starts with the Root's name, consume the first segment and start searching from the next
    if (segments.isNotEmpty && segments.first == root.name) {
      traverse(root, segments.sublist(1));
    } else {
      // Fault tolerance: If the path doesn't start with "Device", start searching directly from the Root
      traverse(root, segments);
    }

    return results;
  }
}

/// An interface for a node that can be traversed by [PathResolver].
///
/// [T] is the concrete implementation type (e.g., `UspNode` on the server-side,
/// or `LiteNode` on the client-side).
abstract class ITraversableNode<T extends ITraversableNode<T>> {
  /// The name of the node, used for matching path segments.
  String get name;

  /// Gets a child node by name (for exact matching).
  ///
  /// Returns null if this is not a container node or the child is not found.
  T? getChild(String name);

  /// Gets all child nodes (for wildcard matching).
  ///
  /// Returns an empty iterable if this is not a container node.
  Iterable<T> getAllChildren();
}

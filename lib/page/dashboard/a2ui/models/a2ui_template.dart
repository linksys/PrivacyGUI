import 'package:equatable/equatable.dart';

/// A node in the A2UI template tree.
///
/// Templates define the UI structure of an A2UI widget using a tree
/// of nodes, where each node represents a widget type with its properties.
sealed class A2UITemplateNode extends Equatable {
  /// The widget type (e.g., 'Column', 'AppText', 'AppIcon').
  final String type;

  /// Widget properties.
  final Map<String, dynamic> properties;

  const A2UITemplateNode({
    required this.type,
    this.properties = const {},
  });

  /// Creates a template node from JSON.
  factory A2UITemplateNode.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'Container';
    final properties = Map<String, dynamic>.from(
        json['properties'] as Map? ?? json['props'] as Map? ?? {});
    final children = json['children'] as List?;

    if (children != null && children.isNotEmpty) {
      return A2UIContainerNode(
        type: type,
        properties: properties,
        children: children
            .map((c) => A2UITemplateNode.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
    }

    return A2UILeafNode(type: type, properties: properties);
  }

  @override
  List<Object?> get props => [type, properties];
}

/// A container node with children.
class A2UIContainerNode extends A2UITemplateNode {
  final List<A2UITemplateNode> children;

  const A2UIContainerNode({
    required super.type,
    super.properties,
    this.children = const [],
  });

  @override
  List<Object?> get props => [type, properties, children];
}

/// A leaf node without children.
class A2UILeafNode extends A2UITemplateNode {
  const A2UILeafNode({
    required super.type,
    super.properties,
  });
}

/// Property value types for A2UI templates.
sealed class A2UIPropValue extends Equatable {
  const A2UIPropValue();

  /// Parses a property value from JSON.
  ///
  /// - String/Number/Boolean → [A2UIStaticValue]
  /// - `{"$bind": "path"}` → [A2UIBoundValue]
  factory A2UIPropValue.fromJson(dynamic json) {
    if (json is Map<String, dynamic> && json.containsKey(r'$bind')) {
      return A2UIBoundValue(json[r'$bind'] as String);
    }
    return A2UIStaticValue(json);
  }
}

/// A static (literal) property value.
class A2UIStaticValue extends A2UIPropValue {
  final dynamic value;

  const A2UIStaticValue(this.value);

  @override
  List<Object?> get props => [value];
}

/// A data-bound property value.
class A2UIBoundValue extends A2UIPropValue {
  /// The data path to bind to (e.g., 'router.deviceCount').
  final String path;

  const A2UIBoundValue(this.path);

  @override
  List<Object?> get props => [path];
}

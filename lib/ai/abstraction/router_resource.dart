import 'package:equatable/equatable.dart';

/// Describes a router resource that can be queried via AI.
///
/// This maps to MCP's Resource concept.
class RouterResourceDescriptor extends Equatable {
  /// Unique resource URI (e.g., 'router://devices', 'router://wifi')
  final String uri;

  /// Human-readable name
  final String name;

  /// MIME type of the resource content
  final String mimeType;

  /// Description for AI understanding
  final String description;

  const RouterResourceDescriptor({
    required this.uri,
    required this.name,
    this.mimeType = 'application/json',
    this.description = '',
  });

  @override
  List<Object?> get props => [uri, name, mimeType, description];
}

/// Content of a router resource.
class RouterResource extends Equatable {
  /// The resource URI this content belongs to
  final String uri;

  /// The content as a JSON-encodable map
  final Map<String, dynamic> content;

  /// Optional text representation
  final String? text;

  const RouterResource({
    required this.uri,
    required this.content,
    this.text,
  });

  @override
  List<Object?> get props => [uri, content, text];
}

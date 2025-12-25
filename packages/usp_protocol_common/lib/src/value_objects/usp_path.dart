import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usp_path.g.dart';

/// A representation of a USP (User Services Platform) path.
///
/// This class provides utilities for parsing, validating, and normalizing USP paths.
@JsonSerializable()
class UspPath {
  /// The segments of the USP path.
  final List<String> segments;

  /// Whether the path contains a wildcard (`*`).
  final bool hasWildcard;

  /// A map of alias filters for the path.
  final Map<String, String> aliasFilter;

  /// Creates a new [UspPath].
  UspPath(
    this.segments, {
    this.hasWildcard = false,
    Map<String, String>? aliasFilter,
  }) : aliasFilter = aliasFilter ?? const {};

  /// Creates a new [UspPath] from a JSON map.
  factory UspPath.fromJson(Map<String, dynamic> json) =>
      _$UspPathFromJson(json);

  /// Converts this [UspPath] to a JSON map.
  Map<String, dynamic> toJson() => _$UspPathToJson(this);

  /// Parses a raw path string into a [UspPath] object.
  factory UspPath.parse(String rawPath) {
    if (rawPath.isEmpty) {
      return UspPath([]);
    }

    final cleanedPath = rawPath.trim();
    final List<String> parsedSegments = [];
    bool wildcardFound = false;
    Map<String, String> parsedAliasFilter = {};

    // Simple handling for Alias [Key=="Value"]
    final aliasRegex = RegExp(r'\[(.*?)\]');
    final aliasMatch = aliasRegex.firstMatch(cleanedPath);

    if (aliasMatch != null) {
      final filter = aliasMatch.group(1)!;
      final parts = filter.split('==');
      if (parts.length == 2) {
        parsedAliasFilter[parts[0]] = parts[1].replaceAll('"', '');
      }
    }

    final pathWithoutAlias = cleanedPath.replaceAll(aliasRegex, '');
    // Handle trailing dots like in "Device."
    final parts = pathWithoutAlias.split('.');

    for (var part in parts) {
      if (part == '*') {
        wildcardFound = true;
      }
      if (part.isNotEmpty) {
        parsedSegments.add(part);
      }
    }

    return UspPath(
      parsedSegments,
      hasWildcard: wildcardFound,
      aliasFilter: parsedAliasFilter,
    );
  }

  /// The full path string.
  String get fullPath => segments.join('.');

  /// The name of the path, which is the last segment.
  String get name => segments.isNotEmpty ? segments.last : '';

  /// The parent path of this path.
  ///
  /// Returns null if this path is the root.
  UspPath? get parent {
    if (segments.isEmpty) {
      return null; // Root has no parent
    }
    return UspPath(segments.sublist(0, segments.length - 1));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UspPath &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(segments, other.segments) &&
          hasWildcard == other.hasWildcard &&
          const MapEquality().equals(aliasFilter, other.aliasFilter);

  @override
  int get hashCode =>
      const ListEquality().hash(segments) ^
      hasWildcard.hashCode ^
      const MapEquality().hash(aliasFilter);

  @override
  String toString() => 'UspPath($fullPath)';
}

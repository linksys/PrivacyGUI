/// Resolves `$bind` expressions in a widget template JSON tree.
///
/// Walks the tree recursively. When a value is a Map with a single
/// `$bind` key, replaces it with the corresponding value from [dataMap].
/// If the bound path is not found, substitutes `--` as a placeholder.
///
/// Also normalizes the JSON structure for UiTreeBuilder compatibility:
/// - Renames `properties` → `props` (UiTreeBuilder reads `child['props']`)
/// - Merges root-level `children` into `props` (UiTreeBuilder reads
///   `props['children']`, not sibling-level `children`)
Map<String, dynamic> resolveBindings(
  Map<String, dynamic> template,
  Map<String, dynamic> dataMap,
) {
  return _resolveMap(template, dataMap);
}

Map<String, dynamic> _resolveMap(
  Map<String, dynamic> map,
  Map<String, dynamic> dataMap,
) {
  final result = <String, dynamic>{};
  for (final entry in map.entries) {
    // Rename "properties" -> "props" for UiTreeBuilder
    final key = entry.key == 'properties' ? 'props' : entry.key;
    result[key] = _resolveValue(entry.value, dataMap);
  }

  // UiTreeBuilder reads children from inside the props map (line 39:
  // `props['children']`). Widget JSON places children as a sibling of
  // properties at the same level. When we rename properties → props,
  // UiTreeBuilder picks up the props value instead of falling back to the
  // full node object — which loses root-level children.
  // Fix: merge children into props so UiTreeBuilder can find them.
  if (result.containsKey('props') &&
      result['props'] is Map<String, dynamic> &&
      result.containsKey('children')) {
    (result['props'] as Map<String, dynamic>)['children'] = result['children'];
    result.remove('children');
  }

  return result;
}

dynamic _resolveValue(dynamic value, Map<String, dynamic> dataMap) {
  if (value is Map<String, dynamic>) {
    // Check for $bind expression: {"$bind": "Device.X.Y"}
    if (value.length == 1 && value.containsKey(r'$bind')) {
      final path = value[r'$bind'] as String;
      final resolved = dataMap[path];
      return resolved?.toString() ?? '--';
    }
    // Recurse into nested maps
    return _resolveMap(value, dataMap);
  }
  if (value is List) {
    return value.map((item) => _resolveValue(item, dataMap)).toList();
  }
  // Primitives pass through
  return value;
}

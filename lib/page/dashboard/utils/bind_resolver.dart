import 'template_directives.dart';

/// Resolves template directives in a widget template JSON tree.
///
/// Supported directives:
/// - `$bind` — single value lookup from [dataMap]
/// - `$transform` — single-value pipeline (divide, multiply, fn, etc.)
/// - `$compute` — multi-value computation (percent_used, template, etc.)
/// - `$visible` — conditional show/hide (node-level, returns `_hidden` sentinel)
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
  // $visible check — if false, return sentinel to skip rendering.
  // Evaluated first to avoid resolving the entire subtree unnecessarily.
  if (map.containsKey(r'$visible')) {
    final visible = evaluateVisible(
      map[r'$visible'],
      (v) => _resolveValue(v, dataMap),
    );
    if (!visible) return const {'_hidden': true};
  }

  final result = <String, dynamic>{};
  for (final entry in map.entries) {
    if (entry.key == r'$visible') continue; // strip from output
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
    // $bind — single value lookup
    if (value.containsKey(r'$bind')) {
      final path = value[r'$bind'] as String;
      final resolved = dataMap[path];
      return resolved?.toString() ?? '--';
    }
    // $transform — single-value pipeline
    if (value.containsKey(r'$transform')) {
      return evaluateTransform(
        value[r'$transform'] as Map<String, dynamic>,
        (v) => _resolveValue(v, dataMap),
      );
    }
    // $compute — multi-value computation
    if (value.containsKey(r'$compute')) {
      return evaluateCompute(
        value[r'$compute'] as Map<String, dynamic>,
        (v) => _resolveValue(v, dataMap),
      );
    }
    // Regular map — recurse
    return _resolveMap(value, dataMap);
  }
  if (value is List) {
    return value
        .map((item) => _resolveValue(item, dataMap))
        .where((item) => item is! Map || !item.containsKey('_hidden'))
        .toList();
  }
  // Primitives pass through
  return value;
}

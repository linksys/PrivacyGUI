import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/transforms.g.dart';

/// Callback type for recursive value resolution.
///
/// Used by directive evaluators to resolve nested `$bind`, `$transform`,
/// and `$compute` expressions within their own config.
typedef ResolveValue = dynamic Function(dynamic value);

// ---------------------------------------------------------------------------
// $transform — single-value pipeline
// ---------------------------------------------------------------------------

/// Evaluates a `$transform` directive.
///
/// Two modes:
/// - **Function**: `{"input": ..., "fn": "formatBandwidth", "precision": 2}`
/// - **Pipeline**: `{"input": ..., "ops": [{"type": "divide", "by": 1024}, ...]}`
dynamic evaluateTransform(
  Map<String, dynamic> config,
  ResolveValue resolveValue,
) {
  try {
    final input = resolveValue(config['input']);

    // Function mode
    if (config.containsKey('fn')) {
      return _applyFunction(config['fn'] as String, input, config);
    }

    // Pipeline mode
    final ops = config['ops'] as List? ?? [];
    dynamic current = input;
    for (final op in ops) {
      if (op is! Map<String, dynamic>) continue;
      current = _applyOp(current, op);
    }
    return current;
  } catch (e) {
    logger.w('[Directive] \$transform error: $e');
    return '--';
  }
}

dynamic _applyOp(dynamic current, Map<String, dynamic> op) {
  final type = op['type'] as String? ?? '';
  switch (type) {
    case 'divide':
      final by = _toDouble(op['by']);
      return by == 0 ? double.nan : _toDouble(current) / by;
    case 'multiply':
      return _toDouble(current) * _toDouble(op['by']);
    case 'add':
      return _toDouble(current) + _toDouble(op['value']);
    case 'round':
      final precision = op['precision'] as int? ?? 0;
      return double.parse(_toDouble(current).toStringAsFixed(precision));
    case 'floor':
      return _toDouble(current).floor();
    case 'ceil':
      return _toDouble(current).ceil();
    case 'prefix':
      return '${op['value'] ?? ''}$current';
    case 'suffix':
      return '$current${op['value'] ?? ''}';
    case 'map':
      final mappings = op['mappings'] as Map<String, dynamic>? ?? {};
      final key = current?.toString() ?? '';
      return mappings[key] ?? op['default'] ?? key;
    case 'threshold':
      return _applyThreshold(current, op);
    case 'fn':
      return _applyFunction(op['name'] as String? ?? '', current, op);
    default:
      logger.w('[Directive] Unknown \$transform op: $type');
      return current;
  }
}

dynamic _applyThreshold(dynamic current, Map<String, dynamic> op) {
  final value = _toDouble(current);
  final ranges = op['ranges'] as List? ?? [];
  for (final range in ranges) {
    if (range is! Map<String, dynamic>) continue;
    final min = range['min'] as num?;
    final max = range['max'] as num?;
    if (min != null && value < min) continue;
    if (max != null && value > max) continue;
    return range['label'] ?? '--';
  }
  return op['default'] ?? '--';
}

/// Whitelisted function registry mapping to [Transforms] static methods.
dynamic _applyFunction(String name, dynamic input, Map<String, dynamic> config) {
  final precision = config['precision'] as int?;
  switch (name) {
    case 'formatBandwidth':
      return Transforms.formatBandwidth(_toDouble(input), precision: precision ?? 2);
    case 'formatDuration':
      return Transforms.formatDuration(_toInt(input));
    case 'formatBytes':
      return Transforms.formatBytes(_toInt(input));
    case 'formatPercent':
      return Transforms.formatPercent(_toDouble(input), precision: precision ?? 1);
    case 'formatNumber':
      return Transforms.formatNumber(_toDouble(input), precision: precision ?? 0);
    case 'formatSpeed':
      return Transforms.formatSpeed(_toDouble(input), precision: precision ?? 2);
    case 'cidrToNetmask':
      return Transforms.cidrToNetmask(_toInt(input));
    default:
      logger.w('[Directive] Unknown \$transform fn: $name');
      return input?.toString() ?? '--';
  }
}

// ---------------------------------------------------------------------------
// $compute — multi-value computation
// ---------------------------------------------------------------------------

/// Evaluates a `$compute` directive.
///
/// Supported ops:
/// - `percent_used` — `(total - free) / total * 100`
/// - `subtract` — `a - b`
/// - `ratio` — `numerator / denominator`
/// - `template` — string interpolation `{key}` → resolved value
dynamic evaluateCompute(
  Map<String, dynamic> config,
  ResolveValue resolveValue,
) {
  try {
    final op = config['op'] as String? ?? '';
    return switch (op) {
      'percent_used' => _computePercentUsed(config, resolveValue),
      'subtract' => _computeSubtract(config, resolveValue),
      'ratio' => _computeRatio(config, resolveValue),
      'template' => _computeTemplate(config, resolveValue),
      _ => () {
          logger.w('[Directive] Unknown \$compute op: $op');
          return '--';
        }(),
    };
  } catch (e) {
    logger.w('[Directive] \$compute error: $e');
    return '--';
  }
}

String _computePercentUsed(Map<String, dynamic> config, ResolveValue resolveValue) {
  final total = _toDouble(resolveValue(config['total']));
  final free = _toDouble(resolveValue(config['free']));
  if (total <= 0) return '--';
  return ((total - free) / total * 100).toStringAsFixed(1);
}

dynamic _computeSubtract(Map<String, dynamic> config, ResolveValue resolveValue) {
  final a = _toDouble(resolveValue(config['a']));
  final b = _toDouble(resolveValue(config['b']));
  return a - b;
}

dynamic _computeRatio(Map<String, dynamic> config, ResolveValue resolveValue) {
  final numerator = _toDouble(resolveValue(config['numerator']));
  final denominator = _toDouble(resolveValue(config['denominator']));
  if (denominator == 0) return '--';
  return numerator / denominator;
}

String _computeTemplate(Map<String, dynamic> config, ResolveValue resolveValue) {
  final format = config['format'] as String? ?? '';
  final values = config['values'] as Map<String, dynamic>? ?? {};

  // Resolve all values (may contain $bind, $transform, $compute)
  final resolved = values.map(
    (k, v) => MapEntry(k, resolveValue(v)?.toString() ?? ''),
  );

  // Interpolate: {key} → resolved[key]
  return format.replaceAllMapped(
    RegExp(r'\{(\w+)\}'),
    (match) => resolved[match.group(1)] ?? '',
  );
}

// ---------------------------------------------------------------------------
// $visible — conditional show/hide
// ---------------------------------------------------------------------------

/// Evaluates a `$visible` directive.
///
/// Returns `true` if the node should be rendered, `false` if hidden.
///
/// Two modes:
/// - **Simple** (truthy): `{"$visible": {"$bind": "Device.X.Enabled"}}`
/// - **Condition**: `{"$visible": {"condition": "neq", "value": ..., "expected": ...}}`
bool evaluateVisible(
  dynamic config,
  ResolveValue resolveValue,
) {
  try {
    final resolved = resolveValue(config);

    // If resolved to a condition map (has 'condition' key), evaluate it
    if (resolved is Map<String, dynamic> && resolved.containsKey('condition')) {
      return _evaluateCondition(resolved, resolveValue);
    }

    // Simple truthy check
    return _isTruthy(resolved);
  } catch (e) {
    logger.w('[Directive] \$visible error: $e');
    return true; // Default to visible on error
  }
}

bool _evaluateCondition(Map<String, dynamic> config, ResolveValue resolveValue) {
  final condition = config['condition'] as String? ?? 'eq';
  final rawValue = resolveValue(config['value']);
  final rawExpected = config['expected'];

  switch (condition) {
    case 'eq':
      return _toString(rawValue) == _toString(rawExpected);
    case 'neq':
      return _toString(rawValue) != _toString(rawExpected);
    case 'gt':
      return _toDouble(rawValue) > _toDouble(rawExpected);
    case 'gte':
      return _toDouble(rawValue) >= _toDouble(rawExpected);
    case 'lt':
      return _toDouble(rawValue) < _toDouble(rawExpected);
    case 'lte':
      return _toDouble(rawValue) <= _toDouble(rawExpected);
    case 'contains':
      return _toString(rawValue).contains(_toString(rawExpected));
    case 'in':
      if (rawExpected is List) {
        return rawExpected.map((e) => _toString(e)).contains(_toString(rawValue));
      }
      return false;
    default:
      logger.w('[Directive] Unknown \$visible condition: $condition');
      return true;
  }
}

/// Truthy: non-null, non-empty, not "false", not "0", not "--", not 0.
bool _isTruthy(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return value.isNotEmpty &&
        value != 'false' &&
        value != '0' &&
        value != '--';
  }
  return true;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _toString(dynamic value) => value?.toString() ?? '';

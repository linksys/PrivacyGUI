import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Mixin that enables [Equatable] state classes to output structured JSON
/// for diagnostic logging.
///
/// Classes using this mixin must define [namedProps] instead of [props].
/// The mixin automatically derives [props] from [namedProps].values and
/// overrides [toString] to produce JSON output.
///
/// Usage:
/// ```dart
/// class MyData extends Equatable with DiagnosticLoggable {
///   final String name;
///   final int count;
///
///   const MyData({required this.name, required this.count});
///
///   @override
///   Map<String, Object?> get namedProps => {
///     'name': name,
///     'count': count,
///   };
///
///   // Opt-in to state log caching (for Data providers)
///   @override
///   bool get loggable => true;
/// }
/// ```
///
/// The [toString] output will be:
/// ```json
/// {"name":"value","count":42}
/// ```
mixin DiagnosticLoggable on Equatable {
  /// Named properties for both equality comparison and JSON serialization.
  ///
  /// Keys become JSON field names; values are used for both equality checks
  /// (via [props]) and JSON output (via [toString]).
  Map<String, Object?> get namedProps;

  /// Whether this state should be captured by [StateLogObserver].
  ///
  /// Default is `true`. Override to `false` to exclude from diagnostic reports.
  bool get loggable => true;

  @override
  List<Object?> get props => namedProps.values.toList();

  @override
  String toString() {
    try {
      return jsonEncode(_toJsonSafe(namedProps));
    } catch (e) {
      return '${runtimeType.toString()}(${namedProps.entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
    }
  }

  /// Recursively converts values to JSON-safe representations.
  Object? _toJsonSafe(Object? value) {
    if (value == null || value is bool || value is num || value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map<String, Object?>) {
      return value.map((k, v) => MapEntry(k, _toJsonSafe(v)));
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toJsonSafe(v)));
    }
    if (value is Iterable) {
      return value.map(_toJsonSafe).toList();
    }
    if (value is DiagnosticLoggable) {
      return _toJsonSafe(value.namedProps);
    }
    if (value is Equatable) {
      return value.props.map(_toJsonSafe).toList();
    }
    return value.toString();
  }
}

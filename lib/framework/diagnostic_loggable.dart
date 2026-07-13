import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Structured-JSON diagnostic contract, decoupled from [Equatable].
///
/// A type mixes in [DiagnosticNamed] to expose [namedProps] — a keyed view of
/// its fields — so it renders as `{"key":value}` (not an opaque
/// `Instance of '...'`) when nested inside another loggable's JSON output.
///
/// Use this directly for models that use `with EquatableMixin` (rather than
/// `extends Equatable`) and therefore cannot mix in [DiagnosticLoggable], which
/// is constrained `on Equatable`. Such models keep their own [props] for
/// equality and add [namedProps] purely for diagnostics — the two are
/// independent:
/// ```dart
/// class MeshNetwork with EquatableMixin, DiagnosticNamed {
///   @override
///   List<Object?> get props => [master, slaves];       // equality
///   @override
///   Map<String, Object?> get namedProps => {            // diagnostics
///         'master': master,
///         'slaves': slaves,
///       };
/// }
/// ```
mixin DiagnosticNamed {
  /// Stable identifier for diagnostic logging.
  ///
  /// Used as the cache key in [StateLogObserver] instead of [runtimeType],
  /// which can be mangled in dart2js minified builds.
  ///
  /// Default returns [runtimeType.toString()]. Override for web-safe stability:
  /// ```dart
  /// @override
  /// String get diagnosticName => 'MyData';
  /// ```
  String get diagnosticName => runtimeType.toString();

  /// Named properties for JSON serialization. Keys become JSON field names.
  Map<String, Object?> get namedProps;

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
    if (value is Enum) {
      return value.name;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Duration) {
      return value.inMilliseconds;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toJsonSafe(v)));
    }
    if (value is Iterable) {
      return value.map(_toJsonSafe).toList();
    }
    // Keyed JSON for anything exposing namedProps — covers both
    // DiagnosticLoggable (on Equatable) and DiagnosticNamed (on EquatableMixin
    // models like the MeshNetwork entities).
    if (value is DiagnosticNamed) {
      return _toJsonSafe(value.namedProps);
    }
    if (value is Equatable) {
      return value.props.map(_toJsonSafe).toList();
    }
    return value.toString();
  }
}

/// Mixin that enables [Equatable] state classes to output structured JSON
/// for diagnostic logging.
///
/// Classes using this mixin must define [namedProps] instead of [props].
/// The mixin automatically derives [props] from [namedProps].values and
/// overrides [toString] to produce JSON output.
///
/// For models built with `with EquatableMixin` (not `extends Equatable`), use
/// [DiagnosticNamed] instead — this mixin's `on Equatable` constraint cannot
/// be satisfied by them.
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
mixin DiagnosticLoggable on Equatable implements DiagnosticNamed {
  @override
  String get diagnosticName => runtimeType.toString();

  /// Named properties for both equality comparison and JSON serialization.
  ///
  /// Keys become JSON field names; values are used for both equality checks
  /// (via [props]) and JSON output (via [toString]).
  @override
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
  ///
  /// Mirrors [DiagnosticNamed._toJsonSafe]; kept as a separate copy because
  /// [DiagnosticLoggable] is constrained `on Equatable` (not on
  /// [DiagnosticNamed]) so existing `extends Equatable with DiagnosticLoggable`
  /// classes need no change.
  @override
  Object? _toJsonSafe(Object? value) {
    if (value == null || value is bool || value is num || value is String) {
      return value;
    }
    if (value is Enum) {
      return value.name;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Duration) {
      return value.inMilliseconds;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _toJsonSafe(v)));
    }
    if (value is Iterable) {
      return value.map(_toJsonSafe).toList();
    }
    // Keyed JSON for anything exposing namedProps — covers both
    // DiagnosticLoggable and DiagnosticNamed (EquatableMixin models like the
    // MeshNetwork entities).
    if (value is DiagnosticNamed) {
      return _toJsonSafe(value.namedProps);
    }
    if (value is Equatable) {
      return value.props.map(_toJsonSafe).toList();
    }
    return value.toString();
  }
}

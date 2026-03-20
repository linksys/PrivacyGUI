import 'dart:convert';

import 'package:equatable/equatable.dart';

/// A generic wrapper for data that needs dirty-checking.
/// `T` represents the settings data class.
class Preservable<T extends Equatable> extends Equatable {
  final T original;
  final T current;

  const Preservable({required this.original, required this.current});

  /// True if the current data is different from the original.
  bool get isDirty => original != current;

  /// Returns a new instance with an updated `current` value.
  Preservable<T> update(T newCurrent) => copyWith(current: newCurrent);

  /// Returns a new instance where `original` is updated to match `current`.
  /// This is called after a successful save operation.
  Preservable<T> saved() => copyWith(original: current);

  Preservable<T> copyWith({T? original, T? current}) {
    return Preservable<T>(
      original: original ?? this.original,
      current: current ?? this.current,
    );
  }

  @override
  List<Object?> get props => [original, current];

  /// Creates an instance from a map, using a provided function to deserialize [T].
  factory Preservable.fromMap(
    Map<String, dynamic> map,
    T Function(dynamic map) fromMapT,
  ) {
    return Preservable<T>(
      original: fromMapT(map['original']),
      current: fromMapT(map['current']),
    );
  }

  /// Creates an instance from a JSON string, using a provided function to deserialize [T].
  factory Preservable.fromJson(
    String source,
    T Function(dynamic map) fromMapT,
  ) =>
      Preservable.fromMap(json.decode(source), fromMapT);

  /// Converts the instance to a map, using a provided function to serialize [T].
  Map<String, dynamic> toMap(Map<String, dynamic> Function(T value) toMapT) {
    return {
      'original': toMapT(original),
      'current': toMapT(current),
    };
  }

  /// Converts the instance to a JSON string, using a provided function to serialize [T].
  String toJson(Map<String, dynamic> Function(T value) toMapT) =>
      json.encode(toMap(toMapT));
}

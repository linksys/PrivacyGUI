import 'package:usp_protocol_common/src/value_objects/usp_value_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usp_value.g.dart';

/// A representation of a USP (User Services Platform) value.
///
/// This class encapsulates a value of a specific USP data type.
@JsonSerializable(genericArgumentFactories: true)
class UspValue<T> {
  /// The actual value.
  final T value;

  /// The USP data type of the value.
  final UspValueType type;

  /// Creates a new [UspValue].
  UspValue(this.value, this.type);

  /// Creates a new [UspValue] from a JSON map.
  factory UspValue.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$UspValueFromJson(json, fromJsonT);

  /// Converts this [UspValue] to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$UspValueToJson(this, toJsonT);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UspValue &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          type == other.type;

  @override
  int get hashCode => value.hashCode ^ type.hashCode;

  @override
  String toString() => 'UspValue{value: $value, type: $type}';
}

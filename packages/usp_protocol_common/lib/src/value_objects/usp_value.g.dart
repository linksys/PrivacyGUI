// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usp_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UspValue<T> _$UspValueFromJson<T>(
  Map json,
  T Function(Object? json) fromJsonT,
) => UspValue<T>(
  fromJsonT(json['value']),
  $enumDecode(_$UspValueTypeEnumMap, json['type']),
);

Map<String, dynamic> _$UspValueToJson<T>(
  UspValue<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'value': toJsonT(instance.value),
  'type': _$UspValueTypeEnumMap[instance.type]!,
};

const _$UspValueTypeEnumMap = {
  UspValueType.string: 'string',
  UspValueType.int: 'int',
  UspValueType.unsignedInt: 'unsignedInt',
  UspValueType.long: 'long',
  UspValueType.unsignedLong: 'unsignedLong',
  UspValueType.boolean: 'boolean',
  UspValueType.dateTime: 'dateTime',
  UspValueType.base64: 'base64',
  UspValueType.hexBinary: 'hexBinary',
};

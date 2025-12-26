// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usp_path.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UspPath _$UspPathFromJson(Map json) => UspPath(
  (json['segments'] as List<dynamic>).map((e) => e as String).toList(),
  hasWildcard: json['hasWildcard'] as bool? ?? false,
  aliasFilter: (json['aliasFilter'] as Map?)?.map(
    (k, e) => MapEntry(k as String, e as String),
  ),
);

Map<String, dynamic> _$UspPathToJson(UspPath instance) => <String, dynamic>{
  'segments': instance.segments,
  'hasWildcard': instance.hasWildcard,
  'aliasFilter': instance.aliasFilter,
};

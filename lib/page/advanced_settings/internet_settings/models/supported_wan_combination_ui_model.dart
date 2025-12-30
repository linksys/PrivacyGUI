import 'dart:convert';

import 'package:equatable/equatable.dart';

class SupportedWANCombinationUIModel extends Equatable {
  final String wanType;
  final String wanIPv6Type;

  @override
  List<Object?> get props => [wanType, wanIPv6Type];

  const SupportedWANCombinationUIModel({
    required this.wanType,
    required this.wanIPv6Type,
  });

  SupportedWANCombinationUIModel copyWith({
    String? wanType,
    String? wanIPv6Type,
  }) {
    return SupportedWANCombinationUIModel(
      wanType: wanType ?? this.wanType,
      wanIPv6Type: wanIPv6Type ?? this.wanIPv6Type,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'wanType': wanType,
      'wanIPv6Type': wanIPv6Type,
    };
  }

  factory SupportedWANCombinationUIModel.fromMap(Map<String, dynamic> map) {
    return SupportedWANCombinationUIModel(
      wanType: map['wanType'] as String,
      wanIPv6Type: map['wanIPv6Type'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SupportedWANCombinationUIModel.fromJson(String source) =>
      SupportedWANCombinationUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

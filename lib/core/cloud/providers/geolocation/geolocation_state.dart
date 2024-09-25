// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class GeolocationState extends Equatable {
  final String name;
  final String region;
  final String countryCode;

  const GeolocationState({
    required this.name,
    required this.region,
    required this.countryCode,
  });

  GeolocationState copyWith({
    String? name,
    String? region,
    String? countryCode,
  }) {
    return GeolocationState(
      name: name ?? this.name,
      region: region ?? this.region,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'region': region,
      'countryCode': countryCode,
    };
  }

  factory GeolocationState.fromMap(Map<String, dynamic> map) {
    return GeolocationState(
      name: map['name'] as String,
      region: map['region'] as String,
      countryCode: map['countryCode'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory GeolocationState.fromJson(String source) => GeolocationState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [name, region, countryCode];
}

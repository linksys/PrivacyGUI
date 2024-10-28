// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class GeolocationState extends Equatable {
  final String name;
  final String city;
  final String region;
  final String country;
  final String regionCode;

  final String countryCode;
  final String continentCode;

  const GeolocationState({
    required this.name,
    required this.city,
    required this.region,
    required this.country,
    required this.regionCode,
    required this.countryCode,
    required this.continentCode,
  });

  GeolocationState copyWith({
    String? name,
    String? city,
    String? region,
    String? country,
    String? regionCode,
    String? countryCode,
    String? continentCode,
  }) {
    return GeolocationState(
      name: name ?? this.name,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      regionCode: regionCode ?? this.regionCode,
      countryCode: countryCode ?? this.countryCode,
      continentCode: continentCode ?? this.continentCode,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'city': city,
      'region': region,
      'country': country,
      'regionCode': regionCode,
      'countryCode': countryCode,
      'continentCode': continentCode,
    };
  }

  factory GeolocationState.fromMap(Map<String, dynamic> map) {
    return GeolocationState(
      name: map['name'] as String,
      city: map['city'] as String,
      region: map['region'] as String,
      country: map['country'] as String,
      regionCode: map['regionCode'] as String,
      countryCode: map['countryCode'] as String,
      continentCode: map['continentCode'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory GeolocationState.fromJson(String source) =>
      GeolocationState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      name,
      city,
      region,
      country,
      regionCode,
      countryCode,
      continentCode,
    ];
  }
}

extension GeolocationStateExt on GeolocationState {
  String get displayLocationText {
    /// Location display rule:
    /// if has city -> city, countryCode
    /// else if has region -> region, countryCode
    /// else -> country, continentCode

    final (location, locationLevel) = city.isNotEmpty
        ? (city, LocationLevel.city)
        : region.isNotEmpty
            ? (region, LocationLevel.region)
            : (country, LocationLevel.country);
    final code = regionCode.isNotEmpty && locationLevel == LocationLevel.city
        ? regionCode
        : countryCode.isNotEmpty && locationLevel != LocationLevel.country
            ? countryCode
            : continentCode;
    return '${location.isNotEmpty ? '$location, ' : ''} $code';
  }
}

enum LocationLevel {
  city,
  region,
  country;
}

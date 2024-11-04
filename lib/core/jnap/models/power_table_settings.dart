// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class PowerTableSettings extends Equatable {
  final bool isPowerTableSelectable;
  final List<String> supportedCountries;
  final String? country;
  const PowerTableSettings({
    required this.isPowerTableSelectable,
    required this.supportedCountries,
    this.country,
  });

  PowerTableSettings copyWith({
    bool? isPowerTableSelectable,
    List<String>? supportedCountries,
    String? country,
  }) {
    return PowerTableSettings(
      isPowerTableSelectable:
          isPowerTableSelectable ?? this.isPowerTableSelectable,
      supportedCountries: supportedCountries ?? this.supportedCountries,
      country: country ?? this.country,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isPowerTableSelectable': isPowerTableSelectable,
      'supportedCountries': supportedCountries,
      'country': country,
    };
  }

  factory PowerTableSettings.fromMap(Map<String, dynamic> map) {
    return PowerTableSettings(
      isPowerTableSelectable: map['isPowerTableSelectable'] as bool,
      supportedCountries: List<String>.from(map['supportedCountries']),
      country: map['country'] != null ? map['country'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerTableSettings.fromJson(String source) =>
      PowerTableSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props =>
      [isPowerTableSelectable, supportedCountries, country];
}

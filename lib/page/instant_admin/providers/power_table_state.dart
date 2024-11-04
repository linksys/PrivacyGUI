// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';

class PowerTableState extends Equatable {
  final bool isPowerTableSelectable;
  final List<PowerTableCountries> supportedCountries;
  final PowerTableCountries? country;
  const PowerTableState({
    required this.isPowerTableSelectable,
    required this.supportedCountries,
    this.country,
  });

  PowerTableState copyWith({
    bool? isPowerTableSelectable,
    List<PowerTableCountries>? supportedCountries,
    PowerTableCountries? country,
  }) {
    return PowerTableState(
      isPowerTableSelectable:
          isPowerTableSelectable ?? this.isPowerTableSelectable,
      supportedCountries: supportedCountries ?? this.supportedCountries,
      country: country ?? this.country,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPowerTableSelectable': isPowerTableSelectable,
      'supportedCountries': supportedCountries.map((e) => e.name.toUpperCase()),
      'country': country?.name.toUpperCase(),
    }..removeWhere((_, value) => value == null);
  }

  factory PowerTableState.fromMap(Map<String, dynamic> map) {
    return PowerTableState(
      isPowerTableSelectable: map['isPowerTableSelectable'] as bool,
      supportedCountries: List.from(map['supportedCountries'])
          .map<PowerTableCountries>((e) => PowerTableCountries.resolve(e))
          .toList(),
      country: map['country'] != null
          ? PowerTableCountries.resolve(map['country'] as String)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PowerTableState.fromJson(String source) =>
      PowerTableState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
        isPowerTableSelectable,
        supportedCountries,
        country,
      ];
}
